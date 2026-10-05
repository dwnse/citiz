import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createWorld,join,action,snapshot} from '../src/world.mjs';
import {resourcesTick} from '../src/harvesting.mjs';
import {openStore} from '../src/storage.mjs';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join as pathJoin} from 'node:path';
const act=(w,p,type,extra={},now=1000)=>action(w,p,{type,seq:p.seq+1,...extra},now);
function fixture(kind='tree'){const w=createWorld(0),p=join(w,'a','A');w.resources=[{id:'r',kind,x:40,y:60,hits:5,maxHits:5,readyAt:0}];p.x=40;p.y=63;return {w,p,r:w.resources[0]};}
test('herramienta extrae materiales de madera y piedra sin gastar balas; cinco golpes agotan',()=>{
 for(const kind of ['tree','rock']){
  const {w,p,r}=fixture(kind);const initial=p.wood,ammo=p.ammo;
  assert.equal(act(w,p,'harvest',{id:r.id}),false);act(w,p,'equip',{item:'tool'});
  assert.equal(act(w,p,'shoot',{angle:0}),false);
  for(let i=0;i<5;i++){p.cooldown=0;assert.ok(act(w,p,'harvest',{id:r.id},1000+i*1000));assert.equal(act(w,p,'harvest',{id:r.id},1000+i*1000),false);}
  assert.equal(p.wood,initial+(kind==='tree'?30:40));assert.equal(p.ammo,ammo);assert.equal(r.hits,0);p.cooldown=0;
  assert.equal(act(w,p,'harvest',{id:r.id},7000),false);
  act(w,p,'equip',{item:'weapon'});assert.ok(act(w,p,'shoot',{angle:0}));
 }
});
test('distancia, línea bloqueada, secuencia y agotamiento compartido impiden duplicación',()=>{
 const {w,p,r}=fixture();act(w,p,'equip',{item:'tool'});p.y=64;assert.equal(act(w,p,'harvest',{id:r.id}),false);p.y=63;
 w.walls.push({x:40,y:61.5,kind:'wall',rot:0,hp:100});assert.equal(act(w,p,'harvest',{id:r.id}),false);w.walls=[];
 r.hits=1;assert.ok(act(w,p,'harvest',{id:r.id}));assert.equal(action(w,p,{type:'harvest',seq:p.seq,id:r.id},2000),false);
 const q=join(w,'b','B');q.x=40;q.y=63;act(w,q,'equip',{item:'tool'});assert.equal(act(w,q,'harvest',{id:r.id}),false);assert.equal(q.wood,100);
});
test('recursos y equipo persisten; regeneración espera si el punto está ocupado',()=>{
 const dir=mkdtempSync(pathJoin(tmpdir(),'cerco-harvest-'));
 try{
  const store=openStore(dir,100),w=store.data.worlds[0],p=join(w,'a','A');snapshot(w,p.id,new Set(),100);
  assert.ok(w.resources.length>0);const r=w.resources[0];r.hits=0;r.readyAt=1000;p.x=r.x;p.y=r.y;p.equipped='tool';store.save();
  const restored=openStore(dir,2000).data.worlds[0],q=restored.players.a,node=restored.resources[0];assert.equal(q.equipped,'tool');assert.equal(node.hits,0);
  resourcesTick(restored,2000);assert.equal(node.hits,0);q.x+=5;resourcesTick(restored,2000);assert.equal(node.hits,5);
 }finally{rmSync(dir,{recursive:true,force:true});}
});
