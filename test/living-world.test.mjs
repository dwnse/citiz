import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createWorld,join,action,snapshot} from '../src/world.mjs';
import {structuresTick} from '../src/structures.mjs';
import {solid} from '../src/navigation.mjs';
import {initializeAdventure,adventureTick} from '../src/adventure.mjs';
import {cosmeticAction,cosmetics} from '../src/rewards.mjs';
import {openStore} from '../src/storage.mjs';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join as pathJoin} from 'node:path';
import {travel,PASSAGES} from '../src/passages.mjs';

function setup(){
 const w=createWorld(1000),p=join(w,'a','A'),c=w.communities[0];
 w.obstacles=[];w.resources=[{id:'tree',kind:'tree',x:72,y:80,hits:5,maxHits:5}];w.resourceLayout=2;w.nearbyResourcesVersion=1;c.settlers=1;
 w.walls=[{id:'home',kind:'shelter',communityId:c.id,x:60,y:80,hp:300},{id:'mill',kind:'sawmill',communityId:c.id,x:66,y:80,hp:220,stock:0}];
 return {w,p,c,online:new Set([p.id]),mill:w.walls[1]};
}
function advance(w,online,seconds,start=2000){for(let i=0;i<seconds*10;i++){structuresTick(w,.1,start+i*100,online);for(const npc of w.workers)assert.equal(solid(w,npc.x,npc.y),false,'resident cannot cross geometry');}}

test('trabajador viaja, extrae y entrega; un recurso encerrado no produce a distancia',()=>{
 const {w,online,mill}=setup();advance(w,online,1);assert.equal(mill.stock,0);assert.equal(w.workers.length,1);
 advance(w,online,32,3000);assert.equal(mill.stock,6);assert.equal(w.resources[0].hits,4);
 const second=setup();second.w.obstacles=[{x:70,y:80,sx:.3,sy:2.5},{x:74,y:80,sx:.3,sy:2.5},{x:72,y:77.5,sx:2,sy:.3},{x:72,y:82.5,sx:2,sy:.3}];
 advance(second.w,second.online,35);assert.equal(second.mill.stock,0);assert.equal(second.w.resources[0].hits,5);assert.match(second.w.workers[0].status,/bloqueado/);
});
test('carga persiste sin duplicarse y se recupera si destruyen el puesto',()=>{
 const {w,online,mill}=setup();
 for(let i=0;i<400&&!w.workers?.[0]?.cargo;i++)structuresTick(w,.1,2000+i*100,online);
 assert.equal(w.workers[0].cargo.amount,6);assert.equal(mill.stock,0);
 const directory=mkdtempSync(pathJoin(tmpdir(),'cerco-workers-'));
 try{const store=openStore(directory,2000);store.data.worlds=[w];store.save();const loaded=openStore(directory,3000).data.worlds[0];advance(loaded,online,5,42000);assert.equal(loaded.walls[1].stock,6);assert.equal(loaded.workers[0].cargo,null);assert.equal(loaded.resources[0].hits,4);}finally{rmSync(directory,{recursive:true,force:true});}
 mill.hp=0;structuresTick(w,.1,40000,online);const cargo=w.drops.filter(d=>d.id.startsWith('cargo-'));assert.equal(cargo.length,1);assert.equal(cargo[0].materials.timber,6);
 structuresTick(w,.1,40100,online);assert.equal(w.drops.filter(d=>d.id.startsWith('cargo-')).length,1);
});
test('la proximidad no permite extraer a través de un muro',()=>{
 const {w,online,mill}=setup();
 w.obstacles=[{x:71.2,y:80,sx:.15,sy:1},{x:72.8,y:80,sx:.15,sy:1},{x:72,y:79,sx:.8,sy:.15},{x:72,y:81,sx:.8,sy:.15}];
 advance(w,online,35);assert.equal(mill.stock,0);assert.equal(w.resources[0].hits,5);
});
test('amenazas interrumpen trabajo, desconexión congela residentes y planos respetan ocupantes',()=>{
 const {w,p,online,mill}=setup();advance(w,online,5);const npc=w.workers[0],before={x:npc.x,y:npc.y,work:npc.work};
 advance(w,new Set(),5,7000);assert.equal(npc.x,before.x);assert.equal(npc.work,before.work);
 w.zombies=[{id:'threat',x:npc.x+2,y:npc.y,hp:50}];advance(w,online,1,12000);assert.match(npc.status,/refugio|Refugiado/);assert.equal(mill.stock,0);
 const view=snapshot(w,p.id,online,13000);assert.equal(view.workers.length,1);
});
test('señales se reclaman una vez, tienen alcance y línea de visión, expiran y se pausan sin conexión',()=>{
 const {w,p,online}=setup();w.walls=[];const a=initializeAdventure(w);a.elapsed=120;adventureTick(w,online,0,2000,new Map());
 assert.ok(a.incident);const site=a.sites.find(s=>s.id===a.incident.siteId),act=()=>action(w,p,{type:'expedition',seq:p.seq+1},2000,online);
 assert.equal(act(),false);p.x=site.x;p.y=site.y+3;w.obstacles.push({x:p.x,y:p.y-1,sx:1,sy:.2});assert.equal(act(),false);assert.ok(a.incident);
 w.obstacles=[];p.cargo={kind:'laboratory'};site.readyAt=100000;assert.equal(act(),true);assert.equal(p.medical,3);assert.equal(a.incident,null);assert.equal(act(),false);assert.equal(p.medical,3);
 const elapsed=a.elapsed;adventureTick(w,new Set(),30,2000,new Map());assert.equal(a.elapsed,elapsed);
 a.elapsed=a.incidentNext;adventureTick(w,online,0,2000,new Map());assert.ok(a.incident);a.elapsed=a.incident.endsAt;adventureTick(w,online,0,2000,new Map());assert.equal(a.incident,null);assert.match(a.incidentHistory.at(-1).result,/perdida/);
});
test('patios persisten una sola vez y conservan construcciones, recursos y entradas abiertas',()=>{
 const {w}=setup();const original=structuredClone(w.resources),walls=structuredClone(w.walls),a=initializeAdventure(w),count=w.obstacles.length;assert.ok(count>0);
 initializeAdventure(w);assert.equal(w.obstacles.length,count);assert.deepEqual(w.resources,original);assert.deepEqual(w.walls,walls);
 for(const s of a.sites)for(const dy of [-5,5])assert.equal(w.obstacles.some(o=>o.landmark&&Math.abs(o.x-s.x)<o.sx+.6&&Math.abs(o.y-s.y-dy)<o.sy+.6),false);
});
test('aspectos usan saldo de cuenta, no dan ventajas y no cobran otra vez al equipar o repetir',()=>{
 const {w,p}=setup(),data={worlds:[w],accounts:{key:{id:p.id,profileId:'profile',worldId:w.id}},profiles:{profile:{coins:12,seals:1,titles:[],rewards:{}}}};
 const before={wood:p.wood,hp:p.hp,ammo:p.ammo},buy=(style,seq=p.seq+1)=>cosmeticAction(data,w,p,{style,seq});
 assert.equal(buy('ember'),true);assert.equal(data.profiles.profile.coins,6);assert.equal(p.appearance,'ember');assert.equal(buy('ember',p.seq),false);assert.equal(buy('ember'),true);assert.equal(data.profiles.profile.coins,6);
 assert.equal(buy('seal'),false);assert.equal(data.profiles.profile.seals,1);assert.equal(buy('__proto__'),false);assert.deepEqual({wood:p.wood,hp:p.hp,ammo:p.ammo},before);
 const restored=JSON.parse(JSON.stringify(data));assert.deepEqual(cosmetics(restored,w.id,p.id).owned,['standard','ember']);
});
test('colectores validan distancia, salida, resistencia y espera sin cobrar intentos fallidos',()=>{
 const {w,p}=setup();w.collectors={version:1,rooms:[]};p.stamina=100;assert.equal(travel(w,p,2000),false);assert.equal(p.stamina,100);
 p.x=PASSAGES[0].x;p.y=PASSAGES[0].y;
 w.obstacles=[{x:160,y:114,sx:6,sy:6}];assert.equal(travel(w,p,2000),false);assert.equal(p.stamina,100);
 w.obstacles=[];assert.equal(travel(w,p,2000),true);assert.equal(p.x,160);assert.equal(p.y,114);assert.equal(p.stamina,75);assert.equal(travel(w,p,2001),false);assert.equal(p.stamina,75);
 assert.equal(travel(w,p,17000),true);assert.equal(p.x,50);assert.equal(p.y,96);assert.equal(p.stamina,50);
 p.stamina=24;assert.equal(travel(w,p,33000),false);assert.equal(p.stamina,24);
});
