import {collectorInteraction,collectorsTick} from './collectors.mjs';
import {passages,travel} from './passages.mjs';
import {populationView} from './population.mjs';
import {BALANCE,nextWaveLevel} from './balance.mjs';
import {workerOrder} from './workers.mjs';
import {bossFields,bossTick,pruneFallen,RALLY} from './enemies.mjs';
import {inventory,addMaterials,payRecipe} from './inventory.mjs';
import {adventureAction,adventureTick,adventureView,initializeAdventure,markProgress,weapon,freezePause} from './adventure.mjs';
import {structureAction,structureStatus,buildRow,upgradeStructure,STRUCTURES,catalog,bounds,isSolid,contains,quantize,placementReason,useStructure,structuresTick,definition} from './structures.mjs';
import { randomUUID } from 'node:crypto';
import {initializeResources,harvest,resourcesTick} from './harvesting.mjs';
import {damageInfected,collectLoot} from './loot.mjs';
import {solid,beginNavigation,direction} from './navigation.mjs';
import {makeCommunities,faction,core,vaults,capacity,members,canRaid,protectedRoad,checkElimination,siegeStatus,SIEGE_PRESETS} from './communities.mjs';
import {initializeStory,magicState,effect,interactStory,cast,storyTick,storyView,reservedStorySite} from './story.mjs';
export const CONFIG = { tick: 30, size: 100, radius: 18, maxWalls: 80, waveSeconds: BALANCE.dayWaveSeconds, duration: 30*86400000 };
export const dist = (a,b) => Math.hypot(a.x-b.x,a.y-b.y);
export const buildRadius = (w,p) => CONFIG.radius+(core(w,p).upgrades||0)*6;
export function createWorld(now=Date.now(),mode='development') {
  const communities=makeCommunities();
  const world={version:6,id:randomUUID(),name:'Ciudad cercada',size:220,communities,vault:communities[0].vault,rules:{siege:{...SIEGE_PRESETS[mode]}},obstacles:communities.flatMap(c=>[{id:c.id+'-rock',x:c.x+16,y:c.y+7,sx:2,sy:5},{id:c.id+'-ruin',x:c.x+11,y:c.y-21,sx:5,sy:2}]),startedAt:now,phase:'active',players:{},walls:[],zombies:[],drops:communities.flatMap(c=>[{id:randomUUID(),x:c.x-6,y:c.y+11,...c.resources},{id:randomUUID(),x:c.x+7,y:c.y+8,...c.resources},{id:randomUUID(),x:c.x-10,y:c.y-6,...c.resources}]),wave:0,nextWave:now+BALANCE.firstWaveMs,events:[],shots:[],tick:0};initializeStory(world,now);return world;
}
export function join(w,id,name,communityId='forest') {
  if (w.players[id]) return w.players[id];
  const c=w.communities.find(c=>c.id===communityId);
  if(!c||c.eliminated||c.vault.hp<=0||members(w,c).length>=10||w.phase!=='active'||Object.keys(w.players).length>=capacity(w)) throw Error('Comunidad no disponible, llena o mundo cerrado');
  const spawn=safeSpawn(w,{x:c.x-4,y:c.y+14});if(!spawn)throw Error('No hay una aparición libre');
  const player=w.players[id]={id,communityId:c.id,name:String(name||'Agente').slice(0,18),...spawn,hp:100,armor:30,ammo:12,reserve:60,wood:100,kills:0,alive:true,hunger:100,thirst:100,seq:0,cooldown:0,reload:0,angle:0,respawn:0,intro:false,prologue:0};magicState(player);return player;
}
export function safeSpawn(w,origin) {
  for(let radius=0;radius<=12;radius++)for(let dx=-radius;dx<=radius;dx++)for(let dy=-radius;dy<=radius;dy++){
    if(Math.max(Math.abs(dx),Math.abs(dy))!==radius)continue;
    const x=origin.x+dx,y=origin.y+dy;
    if(!solid(w,x,y)&&!Object.values(w.players).some(p=>p.alive&&Math.hypot(p.x-x,p.y-y)<1.5))return {x,y};
  }return null;
}
export function note(w,text) {w.events.push({id:randomUUID(),text,time:Date.now()});w.events=w.events.slice(-6);}
export function placement(w,p,x,y,kind='wall',rot=0,remote=false) {return !placementReason(w,p,x,y,kind,rot,remote);}
function blocked(w,x,y,r=.6) {return solid(w,x,y,r);}
function move(w,p,dx,dy) {if(!blocked(w,p.x+dx,p.y))p.x+=dx;if(!blocked(w,p.x,p.y+dy))p.y+=dy;}
export function action(w,p,msg,now=Date.now(),online=new Set()) {
  inventory(p);
  const result=performAction(w,p,msg,now,online);
  inventory(p);
  if(result){
    if(msg.type==='harvest')markProgress(p,'harvest');
    if(['build','build_row'].includes(msg.type))markProgress(p,'build');
    if(msg.type==='consume'||(['use','interact'].includes(msg.type)&&/bebido|comido|Comida preparada/.test(p.actionMessage||'')))markProgress(p,'supply');
  }
  return result;
}
function performAction(w,p,msg,now,online) {
  if(w.phase!=='active'||!p.alive||!Number.isSafeInteger(msg.seq)||msg.seq<=p.seq) return false;
  p.seq=msg.seq;
  if(w.pausedBy&&msg.type!=='pause'){p.buildError='Partida pausada. Pulsa P para continuar.';return false;}
  const adventure=adventureAction(w,p,msg,now,online);if(adventure!==null)return adventure;
  const own=faction(w,p),v=core(w,p);
  switch(msg.type) {
    case 'worker_order': return workerOrder(w,p,msg);
    case 'rebuild_vault': {
      if(v.hp>0){p.buildError='La bóveda sigue en pie. Usa E para repararla si está dañada.';return false;}
      if(dist(p,v)>6){p.buildError='Acércate a menos de 6 m de las ruinas de tu bóveda.';return false;}
      if(p.wood<100){p.buildError=`Reconstruir requiere 100 materiales. Te faltan ${100-p.wood}.`;return false;}
      p.wood-=100;v.hp=750;own.eliminated=false;p.actionMessage='Bóveda reconstruida: 750 PV. Construcción y reapariciones restauradas.';note(w,`${own.name} ha reconstruido su bóveda`);return true;
    }
    case 'consume': {
      const key=msg.item;if(!['food','water','medical'].includes(key))return false;
      const stat={food:'hunger',water:'thirst',medical:'hp'}[key];
      if(!(p[key]>0)){p.buildError='No tienes ese suministro. Recoge botín con E.';return false;}
      if(p[stat]>=100){p.buildError='Esa necesidad ya está completa.';return false;}
      p[key]--;p[stat]=Math.min(100,p[stat]+({food:35,water:40,medical:30}[key]));p.actionMessage='Suministro utilizado';return true;
    }
    case 'equip':
      if(!['weapon','tool'].includes(msg.item))return false;
      p.equipped=msg.item;p.actionMessage=msg.item==='tool'?'Hacha-pico equipada: apunta a un recurso y mantén clic':weapon(p).name+' equipada';return true;
    case 'harvest': initializeResources(w);return harvest(w,p,msg.id,now);
    case 'staff': case 'unstaff': case 'supply_workers': case 'armor': case 'auto_close': case 'deposit_materials': case 'deposit_ammo': case 'withdraw_ammo':
      return structureAction(w,p,w.walls.find(b=>b.id===msg.id),msg.type,now);
    case 'scavenge': {
      const site=(w.obstacles||[]).filter(o=>String(o.id).endsWith('-ruin')).find(o=>Math.hypot(Math.max(0,Math.abs(p.x-o.x)-o.sx),Math.max(0,Math.abs(p.y-o.y)-o.sy))<=3);
      if(!site||(site.scavengeAfter||0)>now)return false;
      site.scavengeAfter=now+120000;addMaterials(p,'scrap',25);p.reserve+=6;p.actionMessage='Ruinas registradas: 25 chatarra y 6 balas';return true;
    }
    case 'cast': return cast(w,p,msg.power,now);
    case 'upgrade': {
      const level=v.upgrades||0,cost=60+level*30;
      if(level>=3||v.hp<=0||dist(p,v)>6||p.wood<cost)return false;
      p.wood-=cost;v.upgrades=level+1;note(w,`${own.name} · radio ${buildRadius(w,p)}`);return true;
    }
    case 'build_row': return buildRow(w,p,msg,now);
    case 'upgrade_structure': return upgradeStructure(w,p,w.walls.find(b=>b.id===msg.id));
    case 'build': {
      if(!Number.isFinite(msg.x)||!Number.isFinite(msg.y))return false;
      const kind=msg.kind||'wall',rot=msg.rot===1?1:0,x=msg.kind?quantize(msg.x):Math.round(msg.x),y=msg.kind?quantize(msg.y):Math.round(msg.y);
      const reason=placementReason(w,p,x,y,kind,rot,!!msg.kind);if(reason){p.buildError=reason;return false;}
      const d=STRUCTURES[kind];if(!payRecipe(p,d.cost,kind))return false;p.buildError='';
      w.walls.push({id:randomUUID(),communityId:own.id,kind,x,y,rot,hp:d.hp,maxHp:d.hp,open:false,stock:0,producedAt:now});return true;
    }
    case 'reload': if(p.reload<=0&&p.ammo<weapon(p).capacity&&p.reserve>0){p.reload=weapon(p).reload;return true;}return false;
    case 'repair': {const b=w.walls.find(b=>b.id===msg.id),max=b?.maxHp||definition(b||{}).hp;if(!b||b.communityId!==own.id||dist(p,b)>5||p.wood<10||b.hp>=max)return false;p.wood-=10;b.hp=Math.min(max,b.hp+65);return true;}
    case 'dismantle': {const i=w.walls.findIndex(b=>b.id===msg.id&&(b.communityId||'forest')===own.id&&dist(p,b)<5);if(i<0)return false;const [b]=w.walls.splice(i,1);p.wood+=Math.floor(definition(b).cost/2);if(b.kind==='storage'&&(b.stock>0||b.ammoStock>0))w.drops.push({id:randomUUID(),x:b.x,y:b.y,wood:b.stock||0,materials:b.materials,ammo:b.ammoStock||0});return true;}
    case 'use': return useStructure(w,p,w.walls.find(b=>b.id===msg.id),now);
    case 'deposit': {
      const b=w.walls.find(b=>b.kind==='storage'&&b.communityId===own.id&&dist(p,b)<4.5);
      if(b)return structureAction(w,p,b,'deposit_materials',now);if(p.wood<20)return false;
      if(dist(p,v)>6||v.hp<=0)return false;p.wood-=20;own.stock+=20;return true;
    }
    case 'interact': {
      const loot=w.drops.find(d=>dist(d,p)<3);if(loot)return collectLoot(w,p,loot);
      if(passages(w).some(t=>dist(t,p)<=3))return travel(w,p,now);
      const collector=collectorInteraction(w,p,now);if(collector!==null)return collector;
      if(p.cargo&&dist(p,v)<=6)return adventureAction(w,p,{type:'deliver'},now,online);
      if(initializeAdventure(w).sites.some(s=>dist(s,p)<=4))return adventureAction(w,p,{type:'expedition'},now,online);
      if(interactStory(w,p,now))return true;
      const station=w.walls.filter(b=>b.kind&&b.kind!=='wall'&&b.kind!=='spikes'&&b.communityId===own.id&&dist(p,b)<4.5).sort((a,b)=>dist(p,a)-dist(p,b))[0];
      if(station)return useStructure(w,p,station,now);
      const enemy=w.communities.find(c=>c.id!==own.id&&dist(p,c.vault)<6&&c.vault.hp>0);
      if(enemy){if(!canRaid(w,p,enemy.id,online,now)||(p.raidAfter||0)>now||enemy.stock<=0)return false;const amount=Math.min(20,enemy.stock);enemy.stock-=amount;p.wood+=amount;p.raidAfter=now+3000;note(w,`${own.name} roba suministros a ${enemy.name}`);return true;}
      if(dist(p,v)<6&&p.wood>=15&&v.hp>0&&v.hp<1500){p.wood-=15;v.hp=Math.min(1500,v.hp+100);return true;}return false;
    }
    case 'craft': {if(p.wood<15)return false;const bench=w.walls.find(b=>b.kind==='workshop'&&b.communityId===own.id&&dist(p,b)<4.5);p.wood-=15;p.reserve+=bench?30+(bench.level||0)*6:18;return true;}
    case 'intro': return !p.intro&&(p.prologue||0)>=1&&dist(p,v)<=6?interactStory(w,p,now):false;
    case 'shoot': {
      if(p.equipped==='tool')return false;
      if(!Number.isFinite(msg.angle)||p.cooldown>0||p.reload>0||p.ammo<1)return false;
      const gun=weapon(p);p.angle=msg.angle;p.ammo--;p.cooldown=gun.cooldown;p.noiseUntil=now+5000;
      let range=gun.range,target=null,kind='';
      const people=Object.values(w.players).filter(q=>q.id!==p.id&&q.alive&&online.has(q.id));
      for(let t=.3;t<=gun.range;t+=.15){
        const point={x:p.x+Math.cos(p.angle)*t,y:p.y+Math.sin(p.angle)*t};
        if(point.x<2||point.y<2||point.x>w.size-2||point.y>w.size-2||(w.obstacles||[]).some(b=>Math.abs(b.x-point.x)<b.sx&&Math.abs(b.y-point.y)<b.sy)){range=t;break;}
        const wall=w.walls.find(b=>isSolid(b)&&contains(b,point.x,point.y));
        const community=w.communities.find(c=>dist(c.vault,point)<2.2);
        const person=people.find(q=>dist(q,point)<.75),zombie=w.zombies.find(z=>dist(z,point)<(z.boss?1.4:.85));
        if(wall||community||person||zombie){range=t;target=wall||community?.vault||person||zombie;kind=wall?'wall':community?'vault':person?'player':'zombie';
          if(kind!=='zombie'&&!canRaid(w,p,wall?.communityId||community?.id||person?.communityId,online,now))target=null;break;}
      }
      const damage=Math.round(gun.damage*(effect(p,'fury',now)?1.4:1));
      if(target){if(kind==='player')hurt(w,target,damage,now);else if(kind==='zombie'){if(damageInfected(w,target,damage,now,p.communityId))p.kills++;}else target.hp=Math.max(0,target.hp-damage);
        if(target.hp<=0&&kind==='vault')note(w,'Bóveda destruida: esa comunidad ya no puede reaparecer.');
      }
      w.walls=w.walls.filter(b=>b.hp>0);w.zombies=w.zombies.filter(z=>z.hp>0);checkElimination(w);w.shots.push({x:p.x,y:p.y,angle:p.angle,length:range,life:.12});return true;
    }
  }return false;
}
export function spawnWave(w,level,online=null) {
  w.wave++;
  for(const c of w.communities.filter(c=>c.vault.hp>0&&members(w,c).length)){
    const count=online?members(w,c).filter(p=>online.has(p.id)).length:members(w,c).length;
    if(online&&!count)continue;
    const threat=['city','underground'].includes(c.id)?Math.max(2,level):level,n=Math.min(24,Math.ceil((5+threat*3+count*2)*(c.id==='mountain'?.65:1)));
    for(let i=0;i<n&&w.zombies.length<96;i++){const a=i/n*Math.PI*2,point=safeSpawn(w,{x:c.x+Math.cos(a)*33,y:c.y+Math.sin(a)*33});if(!point)continue;w.zombies.push({id:randomUUID(),communityId:c.id,...point,hp:(threat*34+34)*(i%7===0?2:1),maxHp:(threat*34+34)*(i%7===0?2:1),level:threat,variant:i%7===0?'brute':i%3===0?'runner':'walker',attack:0,boss:false});}
    if(threat===3&&w.zombies.length<96){const point=safeSpawn(w,{x:c.x+23,y:c.y+20});if(point)w.zombies.push({id:randomUUID(),communityId:c.id,...point,level:3,attack:0,...bossFields(['healer','reviver','rally','bulwark'][(w.wave-1+w.communities.indexOf(c))%4])});}
  }
  note(w,`Oleada ${w.wave} · amenaza ${level}${level===3?' · El Portador se acerca':''}`);
}
export function tick(w,inputs,online,dt,now=Date.now()) {
  w.tick++;
  if(w.phase!=='active')return;
  if(now>=w.startedAt+CONFIG.duration){w.phase='expired';note(w,'El sello ha cedido. Partida terminada.');return;}
  if(w.pausedBy){freezePause(w,now);if(online.size===1&&online.has(w.pausedBy))return;w.pausedBy=null;}
  adventureTick(w,online,dt,now,inputs);
  collectorsTick(w,online,dt,now,hurt);
  w.shots=w.shots.filter(s=>(s.life-=dt)>0);
  storyTick(w,dt,now,online);
  structuresTick(w,dt,now,online);
  resourcesTick(w,now);
  pruneFallen(w,now);
  beginNavigation(w,dt);
  for(const p of Object.values(w.players)){
    const v=core(w,p);
    p.cooldown=Math.max(0,p.cooldown-dt);
    if(p.reload>0){p.reload=Math.max(0,p.reload-dt);if(p.reload===0){const n=Math.max(0,Math.min(weapon(p).capacity-p.ammo,p.reserve));p.ammo+=n;p.reserve-=n;}}
    if(!p.alive){if(v.hp>0&&now>=p.respawn){const spawn=safeSpawn(w,{x:v.x-4,y:v.y+4});if(spawn){p.alive=true;p.hp=100;p.hunger=70;p.thirst=70;p.x=spawn.x;p.y=spawn.y;p.wood=Math.floor(p.wood*.8);}}continue;}
    if(!online.has(p.id))continue;
    p.hunger=Math.max(0,(p.hunger??100)-dt*BALANCE.hungerPerSecond);p.thirst=Math.max(0,(p.thirst??100)-dt*BALANCE.thirstPerSecond);
    if(p.hunger===0||p.thirst===0){p.hp=Math.max(0,p.hp-dt*2);if(p.hp===0){hurt(w,p,0,now);continue;}}
    const input=inputs.get(p.id);if(input&&now-input.at<350){const x=Math.max(-1,Math.min(1,input.x)),y=Math.max(-1,Math.min(1,input.y)),length=Math.hypot(x,y)||1,speed=(effect(p,'haste',now)?11.2:7)*(p.dodgeUntil>now?2.2:p.sprinting&&(p.stamina??100)>0?1.45:1);move(w,p,x/Math.max(1,length)*speed*dt,y/Math.max(1,length)*speed*dt);if(Number.isFinite(input.angle))p.angle=input.angle;}
  }
  if(online.size&&now>=w.nextWave){if(w.zombies.length<65)spawnWave(w,nextWaveLevel(w.wave),online);w.nextWave=now+(w.adventure?.night?BALANCE.nightWaveSeconds:CONFIG.waveSeconds)*1000;}
  for(const z of w.zombies){
    if(z.hp<=0)continue;
    z.attack=Math.max(0,z.attack-dt);
    const controller=w.players[z.charmedBy];
    if(z.charmUntil>now&&controller?.alive&&online.has(controller.id)){
      const enemy=w.zombies.filter(q=>q!==z&&q.hp>0&&!(q.charmUntil>now)).sort((a,b)=>dist(a,z)-dist(b,z))[0];
      if(enemy&&dist(enemy,z)<=20){
        if(dist(enemy,z)>2){const route=direction(w,z,enemy,2);move(w,z,Math.cos(route.angle)*2.5*dt,Math.sin(route.angle)*2.5*dt);}
        else if(z.attack===0){if(damageInfected(w,enemy,22,now,controller.communityId))controller.kills++;z.attack=1;}
      }continue;
    }
    if(z.charmedBy){delete z.charmedBy;delete z.charmUntil;}
    const players=Object.values(w.players).filter(p=>p.alive&&online.has(p.id));
    let target=players.filter(p=>dist(p,z)<=(z.finalBoss?80:p.noiseUntil>now?34:w.adventure?.night?22:18)).sort((a,b)=>dist(a,z)-dist(b,z))[0];const targetCore=core(w,z.communityId);if(!target)target=targetCore.hp>0?targetCore:null;if(!target)continue;
    if(z.boss&&!z.finalBoss)bossTick(w,z,players,dt,now,hurt);
    if(z.finalBoss){z.ability-=dt;if(z.ability<=2&&z.warning===0)z.warning=2;if(z.warning>0){z.warning-=dt;if(z.warning<=0){for(const p of players)if(dist(p,z)<(z.finalBoss?7:6))hurt(w,p,z.finalBoss?50:35,now);z.ability=z.finalBoss&&z.hp<900?6:10;z.warning=0;}}}
    const isCore=vaults(w).includes(target),d=dist(z,target),route=direction(w,z,target,isCore?3:2.3),a=route.angle,speed=(z.finalBoss&&z.hp<900?2.4:z.boss?1.4:z.variant==='runner'?3.3:z.variant==='brute'?1.2:1.7+z.level*.25)*(z.rallyUntil>now?RALLY.speed:1);
    const obstacle=w.walls.find(b=>isSolid(b)&&contains(b,z.x,z.y,1));
    if(obstacle&&d>2&&!route.routed){if(z.attack===0){obstacle.hp-=(z.boss?35:z.variant==='brute'?28:10+z.level*3)*(z.rallyUntil>now?RALLY.damage:1);z.attack=1;}continue;}
    if(d>(isCore?3:2.3)){const old={x:z.x,y:z.y};move(w,z,Math.cos(a)*speed*dt,Math.sin(a)*speed*dt);if(dist(old,z)<.001)move(w,z,-Math.sin(a)*speed*dt,Math.cos(a)*speed*dt);}
    else if(z.attack===0){if(isCore)target.hp=Math.max(0,target.hp-(z.boss?45:12)*(z.rallyUntil>now?RALLY.damage:1));else hurt(w,target,(z.boss?22:z.variant==='brute'?18:9)*(z.rallyUntil>now?RALLY.damage:1),now);z.attack=1;}
  }
  w.zombies=w.zombies.filter(z=>z.hp>0);w.walls=w.walls.filter(b=>b.hp>0);w.drops=[...w.drops.filter(d=>d.sample),...w.drops.filter(d=>!d.sample).slice(-160)];
  checkElimination(w);
}
function hurt(w,p,damage,now){
  if(p.dodgeUntil>now)damage*=.5;
  if(effect(p,'resist',now))damage*=.6;
  if(effect(p,'shield',now)){const shield=Math.min(p.magic.shieldHp,damage);p.magic.shieldHp-=shield;damage-=shield;}
  const absorbed=Math.min(p.armor,damage*.6);p.armor-=absorbed;p.hp-=damage-absorbed;
  if(p.hp<=0){if(p.sample){w.drops.push({id:randomUUID(),x:p.x,y:p.y,wood:0,ammo:0,sample:true});p.sample=false;}p.sprinting=false;p.hp=0;p.alive=false;p.respawn=now+6000;const m=magicState(p);m.effects={};m.shieldHp=0;note(w,`${p.name} ha caído${core(w,p).hp>0?' · regreso en 6 s':' · sin reaparición'}`);}
}
export function snapshot(w,id,online,now=Date.now(),batch=new WeakMap()){
  initializeAdventure(w);
  initializeResources(w);
  const shared=(key,build)=>{if(!batch.has(key))batch.set(key,build());return batch.get(key);};
  const viewer=w.players[id];for(const p of Object.values(w.players))inventory(p);
  return {...w,workers:(w.workers||[]).filter(q=>dist(q,viewer)<75),adventure:adventureView(w,viewer,now),population:shared(faction(w,viewer),()=>populationView(w,faction(w,viewer),now)),fallen:(w.fallen||[]).filter(z=>dist(z,viewer)<75),resources:w.resources.filter(r=>dist(r,viewer)<85),buildingCatalog:catalog(),story:storyView(w,viewer),effects:(w.effects||[]).filter(f=>dist(f,viewer)<75),vault:core(w,viewer),communityId:viewer.communityId,siege:siegeStatus(w,now),connectedCount:online.size,
    players:Object.values(w.players).filter(p=>p.communityId===viewer.communityId||dist(p,viewer)<70).map(p=>{
      const {seq,...q}=p;
        if(p.communityId!==viewer.communityId)return {id:p.id,name:p.name,x:p.x,y:p.y,hp:p.hp,armor:p.armor,alive:p.alive,angle:p.angle,appearance:p.appearance,equipped:p.equipped||'weapon',toolSwing:p.toolSwing||0,communityId:p.communityId,online:online.has(p.id)};
      return {...q,online:online.has(p.id)};
    }),zombies:w.zombies.filter(z=>dist(z,viewer)<75),walls:w.walls.filter(b=>dist(b,viewer)<85).map(b=>shared(b,()=>({...b,operation:structureStatus(w,b,now)}))),drops:w.drops.filter(d=>dist(d,viewer)<75),shots:w.shots.filter(s=>dist(s,viewer)<75),you:id};
}
