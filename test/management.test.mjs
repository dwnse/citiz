import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createWorld,join,action} from '../src/world.mjs';
import {structuresTick} from '../src/structures.mjs';
import {openStore} from '../src/storage.mjs';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join as pathJoin} from 'node:path';
const fixture=()=>{const w=createWorld(0),p=join(w,'a','A');p.wood=1000;return {w,p};};
const act=(w,p,type,extra={},now=100)=>action(w,p,{type,seq:p.seq+1,...extra},now);

test('fila conectada, coste total y repetición idempotente',()=>{
 const {w,p}=fixture();assert.ok(act(w,p,'build_row',{kind:'wall',x:43,y:58,endX:36.6,endY:58}));
 assert.deepEqual(w.walls.map(b=>[b.x,b.y,b.rot]),[[43,58,0],[39.8,58,0],[36.6,58,0]]);assert.equal(p.wood,940);
 assert.equal(action(w,p,{type:'build_row',seq:p.seq,kind:'wall',x:43,y:58,endX:36.6,endY:58}),false);assert.equal(p.wood,940);
});
test('fila vertical gira las piezas y rechazo es atómico por obstáculos, fondos o límite',()=>{
 const {w,p}=fixture();assert.ok(act(w,p,'build_row',{kind:'spikes',x:40,y:40,endX:40,endY:43.2}));
 assert.deepEqual(w.walls.map(b=>[b.x,b.y,b.rot]),[[40,40,1],[40,43.2,1]]);
 for(const mode of ['funds','obstacle','limit','invalid']){
  const {w,p}=fixture();if(mode==='funds')p.wood=25;if(mode==='obstacle')w.obstacles.push({x:39.8,y:58,sx:1,sy:1});
  const before=p.wood;assert.equal(act(w,p,'build_row',{kind:'wall',x:43,y:58,endX:mode==='limit'?-100:mode==='invalid'?null:36.6,endY:58}),false);
  assert.equal(w.walls.length,0);assert.equal(p.wood,before);
 }
});
test('mejoras limitadas por distancia, propiedad y materiales; reparaciones respetan nuevo máximo',()=>{
 const {w,p}=fixture();act(w,p,'build',{kind:'wall',x:43,y:58});const b=w.walls[0];
 assert.equal(act(w,p,'upgrade_structure',{id:b.id}),false);p.x=43;p.y=61;
 const rival=join(w,'r','R','city');rival.x=43;rival.y=61;assert.equal(act(w,rival,'upgrade_structure',{id:b.id}),false);
 p.wood=0;assert.equal(act(w,p,'upgrade_structure',{id:b.id}),false);p.wood=100;
 b.hp=100;assert.ok(act(w,p,'upgrade_structure',{id:b.id}));assert.equal(b.hp,190);assert.equal(b.maxHp,270);
 assert.ok(act(w,p,'upgrade_structure',{id:b.id}));assert.equal(b.maxHp,360);assert.equal(p.wood,40);
 assert.equal(act(w,p,'upgrade_structure',{id:b.id}),false);
 assert.ok(act(w,p,'repair',{id:b.id}));assert.ok(act(w,p,'repair',{id:b.id}));assert.equal(b.hp,360);
});
test('taller mejorado y producción más rápida mantienen costes y topes',()=>{
 for(const kind of ['workshop','well','garden']){
  const {w,p}=fixture();act(w,p,'build',{kind,x:43,y:58},0);p.x=43;p.y=61;const b=w.walls[0];
  act(w,p,'upgrade_structure',{id:b.id});act(w,p,'upgrade_structure',{id:b.id});
  if(kind==='workshop'){
   const ammo=p.reserve,wood=p.wood;act(w,p,'craft');act(w,p,'use',{id:b.id});assert.equal(p.reserve,ammo+84);assert.equal(p.wood,wood-30);
  }else{structuresTick(w,.1,kind==='well'?20000:40000);assert.equal(b.stock,1);structuresTick(w,.1,600000);assert.equal(b.stock,5);}
 }
});
test('ruinas renovables tienen espera compartida y conservan espera y mejoras al guardar',()=>{
 const dir=mkdtempSync(pathJoin(tmpdir(),'cerco-management-'));
 try{
  const store=openStore(dir,100),w=store.data.worlds[0],p=join(w,'a','A'),q=join(w,'b','B');
  assert.equal(act(w,p,'scavenge'),false);const ruin=w.obstacles.find(o=>o.id.endsWith('-ruin'));p.x=q.x=ruin.x;p.y=q.y=ruin.y+ruin.sy+2;
  assert.ok(act(w,p,'scavenge',{},1000));assert.equal(p.wood,125);assert.equal(p.reserve,66);
  assert.equal(act(w,q,'scavenge',{},1001),false);assert.equal(act(w,p,'scavenge',{},120999),false);
  assert.ok(act(w,q,'scavenge',{},121000));
  p.x=43;p.y=61;act(w,p,'build',{kind:'wall',x:43,y:58});act(w,p,'upgrade_structure',{id:w.walls[0].id});store.save();
  const restored=openStore(dir,122000).data.worlds[0];assert.equal(restored.walls[0].level,1);assert.equal(restored.walls[0].maxHp,270);
  assert.equal(act(restored,restored.players.a,'scavenge',{},122000),false);
  assert.equal(restored.obstacles.find(o=>o.id===ruin.id).scavengeAfter,241000);
 }finally{rmSync(dir,{recursive:true,force:true});}
});
