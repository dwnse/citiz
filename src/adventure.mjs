import {passages,travel} from './passages.mjs';
import {incidentTick,claimIncident} from './incidents.mjs';
import {initializeLandmarks} from './landmarks.mjs';
import {initializeInteriors,expeditionGate,expeditionsTick,campaignStage,encounterHint} from './expeditions.mjs';
import {clearSight} from './story.mjs';
import {addMaterials,inventory} from './inventory.mjs';
import {nextWaveLevel} from './balance.mjs';
export function initializeAdventure(w){
  w.adventure??={elapsed:0,weather:'clear',events:[],sites:w.communities.flatMap(c=>[
    {id:c.id+'-hospital',kind:'hospital',name:'Hospital de campaña',x:c.x-29,y:c.y+29},
    {id:c.id+'-station',kind:'station',name:'Estación de bombeo',x:c.x+29,y:c.y-32},
    {id:c.id+'-laboratory',kind:'laboratory',name:'Laboratorio Umbral',x:c.x-31,y:c.y-30}
  ]).filter(s=>s.x>5&&s.y>5&&s.x<w.size-5&&s.y<w.size-5)};
  initializeLandmarks(w,w.adventure);
  initializeInteriors(w,w.adventure);
  return w.adventure;
}
export function guide(w,p){
  const steps=[['harvest','Consigue madera o piedra: Q equipa el hacha-pico; apunta y mantén clic.'],['build','Levanta tu primera defensa: B → Defensa → Mostrar un lugar disponible.'],['supply','Bebe o come: usa un pozo/huerto o consume suministros con H/Y.'],['expedition','Explora una señal del mapa y pulsa E junto a ella.'],['return','Vuelve a tu bóveda con el resultado de la expedición y pulsa E.']];
  const done=p.journey||{},index=steps.findIndex(([key])=>!done[key]);
  return {step:index<0?5:index,total:5,text:index<0?'Refugio establecido. Investiga las seis voces, amplía tu comunidad y descubre la cura.':steps[index][1]};
}
export function markProgress(p,key){p.journey??={};p.journey[key]=true;}
export function adventureAction(w,p,msg,now,online){
  const a=initializeAdventure(w),fail=message=>{p.buildError=message;return false;};
  if(msg.type==='pause'){
    if(online.size!==1||!online.has(p.id))return fail('La pausa solo está disponible jugando solo.');
    if(w.pausedBy&&w.pausedBy!==p.id)return false;
    freezePause(w,now);w.pausedBy=w.pausedBy?null:p.id;w.pauseAt=now;p.actionMessage=w.pausedBy?'Partida pausada':'Partida reanudada';return true;
  }
  if(msg.type==='travel')return travel(w,p,now);
  if(msg.type==='sprint') {p.sprinting=!!msg.enabled;return true;}
  if(msg.type==='dodge'){
    if((p.stamina??100)<25||p.dodgeAfter>now)return fail('Necesitas 25 de resistencia. La esquiva se recupera en 3 segundos.');
    p.stamina=(p.stamina??100)-25;p.dodgeUntil=now+350;p.dodgeAfter=now+3000;p.actionMessage='Esquiva';return true;
  }
  if(msg.type==='expedition'){
    const site=a.sites.find(s=>Math.hypot(s.x-p.x,s.y-p.y)<=4);
    if(!site)return fail('Acércate a una señal de expedición del minimapa.');
    if(!clearSight(w,p,site))return fail('Rodea el obstáculo para llegar a la señal de expedición.');
    const incident=claimIncident(w,p,site);
    if(incident){p.noiseUntil=now+20000;p.actionMessage=incident.title+': '+incident.reward+'. El ruido atrae infectados.';return true;}
    const gate=expeditionGate(w,p,site,now);if(gate!==null)return gate;
    if((site.readyAt||0)>now)return fail(`Zona registrada. Vuelve en ${Math.ceil((site.readyAt-now)/1000)} s.`);
    if(p.cargo)return fail('Entrega primero el informe que llevas en tu bóveda.');
    site.readyAt=now+180000;
    if(site.encounter){a.expeditionHistory??=[];a.expeditionHistory.push({site:site.name,title:site.encounter.title,phase:site.encounter.phase,communityId:p.communityId});a.expeditionHistory=a.expeditionHistory.slice(-8);site.encounter=null;}
    if(site.kind==='hospital'){p.medical=(p.medical||0)+2;p.food=(p.food||0)+2;}
    if(site.kind==='station'){p.water=(p.water||0)+3;addMaterials(p,'scrap',20);}
    if(site.kind==='laboratory'){addMaterials(p,'components',3);p.reserve+=18;}
    p.cargo={site:site.name,kind:site.kind};p.noiseUntil=now+10000;markProgress(p,'expedition');p.actionMessage=`${site.name}: suministros recogidos. Regresa a tu bóveda con el informe.`;return true;
  }
  if(msg.type==='deliver'){
    const c=w.communities.find(c=>c.id===p.communityId);
    if(!p.cargo||c.vault.hp<=0||Math.hypot(p.x-c.x,p.y-c.y)>6)return fail('Lleva el informe a una bóveda aliada en pie.');
    if(p.cargo.kind==='hospital'){const capacity=w.walls.filter(b=>b.kind==='shelter'&&b.hp>0&&b.communityId===c.id).length*2;if((c.settlers||0)>=capacity)return fail('Construye un refugio con una plaza libre antes de acoger al rescatado.');c.settlers=(c.settlers||0)+1;}
    c.research=(c.research||0)+1;p.expeditions=(p.expeditions||0)+1;p.cargo=null;markProgress(p,'return');addMaterials(p,'reclaimed',15);p.actionMessage='Informe entregado: investigación +1 y 15 materiales recuperados';return true;
  }
  if(msg.type==='weapon'){
    const definitions={pistol:{cost:0,components:0},shotgun:{cost:60,components:2},rifle:{cost:90,components:4}};
    if(!Object.hasOwn(definitions,msg.weapon))return false;const d=definitions[msg.weapon];
    if(p.reload>0)return fail('Termina la recarga antes de cambiar de arma.');
    p.weapons??=['pistol'];
    if(!p.weapons.includes(msg.weapon)){
      inventory(p);
      if(!w.walls.some(b=>b.kind==='workshop'&&b.hp>0&&b.communityId===p.communityId&&Math.hypot(p.x-b.x,p.y-b.y)<4.5))return fail('Acércate a un taller para fabricar esta arma.');
      if(p.materials.components<d.components||p.wood-p.materials.components<d.cost)return fail(`Requiere ${d.cost} materiales y ${d.components} componentes de laboratorio.`);
      p.materials.components-=d.components;p.wood-=d.components;p.wood-=d.cost;inventory(p);p.weapons.push(msg.weapon);
    }
    if(p.reload>0)return fail('Termina la recarga antes de cambiar de arma.');
    p.reserve+=p.ammo;p.ammo=0;p.weapon=msg.weapon;p.equipped='weapon';p.actionMessage='Arma equipada. Pulsa R para cargar.';return true;
  }
  return null;
}
export const WEAPONS={pistol:{name:'Pistola',capacity:12,damage:34,cooldown:.25,range:28,reload:1.4,ammoPerShot:1},shotgun:{name:'Escopeta',capacity:6,damage:90,cooldown:.9,range:11,reload:2.2,ammoPerShot:1},rifle:{name:'Rifle',capacity:20,damage:42,cooldown:.18,range:38,reload:2,ammoPerShot:1}};
export const weapon=p=>WEAPONS[p.weapon]||WEAPONS.pistol;
export function adventureTick(w,online,dt,now,inputs){
  const a=initializeAdventure(w);if(!online.size)return;
  a.elapsed+=dt;a.night=(a.elapsed%600)>=360;a.weather=Math.floor(a.elapsed/180)%3===1?'rain':'clear';
  incidentTick(w,online);
  expeditionsTick(w,online,dt);
  for(const p of Object.values(w.players)){
    if(!p.alive||!online.has(p.id))continue;
    const input=inputs.get(p.id);
    const running=p.sprinting&&(p.stamina??100)>0&&input&&now-input.at<350&&Math.hypot(input.x,input.y)>0;
    p.stamina=Math.max(0,Math.min(100,(p.stamina??100)+(running?-18:12)*dt));
    if(p.stamina===0)p.sprinting=false;
    if(running)p.noiseUntil=now+1200;
  }
}
export function adventureView(w,p,now){
  const a=initializeAdventure(w);
  const phase=campaignStage(w,now),campaignDay=phase.day,campaignPhase=phase.name;
  const threat={seconds:Math.max(0,Math.ceil((w.nextWave-now)/1000)),level:Math.max(['city','underground'].includes(p.communityId)?2:1,nextWaveLevel(w.wave))};
  return {...a,threat,sites:a.sites.map(s=>s.interior?{...s,hint:(s.readyAt||0)>now?`Zona registrada. Vuelve en ${Math.ceil((s.readyAt-now)/1000)} s.`:encounterHint(s,a.elapsed)}:s),passages:passages(w),collectors:w.collectors?.rooms||[],campaignDay,campaignPhase,guide:guide(w,p),weapon:weapon(p),weapons:WEAPONS,paused:!!w.pausedBy,day:1+Math.floor(a.elapsed/600),nextPhase:Math.ceil((a.night?600:360)-a.elapsed%600)};
}

// Shift absolute gameplay deadlines by real paused time; relative timers stay frozen.
export function freezePause(w,now){
  if(!w.pausedBy)return;
  const delta=Math.max(0,now-(w.pauseAt??now));w.pauseAt=now;
  const dates=new Set(['purgedUntil','travelAfter','nextWave','readyAt','producedAt','fuelUntil','attackAfter','closeAt','toggleAfter','recycleAfter','scavengeAfter','respawn','raidAfter','dodgeUntil','dodgeAfter','noiseUntil','fedUntil','interruptedUntil','rallyUntil','diedAt','charmUntil','moveAt','until']);
  function shift(object,parent=''){
    if(!object||typeof object!=='object')return;
    for(const [key,value] of Object.entries(object)){
      if(typeof value==='number'&&value>0&&(dates.has(key)||parent==='cooldowns'||parent==='effects'))object[key]+=delta;
      else if(value&&typeof value==='object')shift(value,key);
    }
  }
  shift(w);
}
