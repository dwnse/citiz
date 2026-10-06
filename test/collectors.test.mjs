import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createWorld,join,action,tick} from '../src/world.mjs';
import {passages,travel} from '../src/passages.mjs';
import {initializeCollectors,collectorInteraction,collectorsTick} from '../src/collectors.mjs';
import {solid,findPath} from '../src/navigation.mjs';
import {freezePause} from '../src/adventure.mjs';
function setup(){const w=createWorld(1000),p=join(w,'a','A');w.obstacles=[];w.resources=[];w.resourceLayout=2;w.nearbyResourcesVersion=1;w.nextWave=1e12;initializeCollectors(w);return {w,p,room:w.collectors.rooms[0],online:new Set([p.id])};}
test('accesos llevan al interior, ruta se recorre y salida no cuesta resistencia',()=>{
 const {w,p,room}=setup();assert.equal(w.collectors.rooms.length,2);assert.equal(passages(w).length,8);
 p.x=50;p.y=96;p.stamina=100;assert.ok(travel(w,p,2000));assert.equal(p.x,69);assert.equal(p.y,105);assert.equal(p.stamina,75);
 assert.equal(solid(w,p.x,p.y),false);const path=findPath(w,p,{x:89,y:105},.5);assert.ok(path.length>10);assert.ok(path.every(q=>!solid(w,q.x,q.y)));
 p.x=89;p.stamina=0;assert.ok(travel(w,p,6000));assert.equal(p.x,160);assert.equal(p.y,114);assert.equal(p.stamina,0);
 assert.ok(room.cache);assert.equal(travel(w,p,6001),false);
});
test('gas requiere ventilación, armario comparte espera y repetir acciones no duplica suministros',()=>{
 const {w,p,room,online}=setup();p.x=room.cache.x;p.y=room.cache.y;
 assert.equal(collectorInteraction(w,p,2000),false);assert.match(p.buildError,/válvula/);
 p.x=room.valve.x;p.y=room.valve.y;const act=()=>action(w,p,{type:'interact',seq:p.seq+1},2000,online);
 assert.ok(act());const deadline=room.purgedUntil;assert.equal(act(),false);assert.equal(room.purgedUntil,deadline);
 p.x=room.cache.x;p.y=room.cache.y;const before=p.reserve;assert.ok(act());assert.equal(p.reserve,before+12);assert.equal(p.materials.components,2);assert.equal(act(),false);assert.equal(p.reserve,before+12);
 const restored=JSON.parse(JSON.stringify(w));assert.equal(restored.collectors.rooms[0].cache.readyAt,182000);
});
test('gas afecta solo a vivos conectados, ventilación y pausa conservan su estado',()=>{
 const {w,p,room,online}=setup();p.x=room.x;p.y=room.y;p.stamina=10;let damage=0;
 collectorsTick(w,new Set(),1,2000,()=>damage++);assert.equal(p.stamina,10);
 collectorsTick(w,online,1,2000,()=>damage++);assert.equal(p.stamina,0);assert.equal(damage,1);
 room.purgedUntil=10000;p.stamina=40;collectorsTick(w,online,1,3000,()=>damage++);assert.equal(p.stamina,40);assert.equal(damage,1);
 w.pausedBy=p.id;w.pauseAt=3000;freezePause(w,5000);assert.equal(room.purgedUntil,12000);
 p.alive=false;collectorsTick(w,online,1,20000,()=>damage++);assert.equal(damage,1);
});
test('migración conserva ocupantes y construcciones; no agrega galerías a mapas de legado',()=>{
 const w=createWorld(1000);w.obstacles=[];w.walls=[{id:'old',x:79,y:105,kind:'storage',hp:280}];initializeCollectors(w);assert.deepEqual(w.collectors.rooms.map(r=>r.id),['east']);assert.equal(w.walls[0].id,'old');
 const count=w.obstacles.length;initializeCollectors(w);assert.equal(w.obstacles.length,count);
 const old=createWorld(1000);old.legacy=true;initializeCollectors(old);assert.equal(old.collectors,undefined);assert.deepEqual(passages(old),[]);
});
test('caminar dentro de la galería respeta paredes y reconexión conserva posición',()=>{
 const {w,p,online}=setup();p.x=79;p.y=105;p.stamina=100;
 for(let i=0;i<100;i++)tick(w,new Map([[p.id,{x:0,y:-1,angle:0,at:2000+i*33}]]),online,1/30,2000+i*33);
 assert.ok(p.y>99.5);assert.equal(solid(w,p.x,p.y),false);assert.equal(join(w,p.id,'Otro').y,p.y);
});
