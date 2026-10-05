import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createWorld,join,action,tick,placement} from '../src/world.mjs';
import {openStore} from '../src/storage.mjs';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join as pathJoin} from 'node:path';
const act=(w,p)=>action(w,p,{type:'rebuild_vault',seq:p.seq+1},1000);
test('bóveda destruida se reconstruye con coste único y restaura construcción y reaparición',()=>{
 const w=createWorld(0),p=join(w,'p','P'),q=join(w,'q','Q');w.vault.hp=0;w.vault.upgrades=2;p.x=46;p.y=50;p.wood=150;q.alive=false;q.hp=0;q.respawn=1000;
 assert.equal(placement(w,p,43,58),false);assert.ok(act(w,p));assert.equal(p.wood,50);assert.equal(w.vault.hp,750);assert.equal(w.vault.upgrades,2);
 assert.equal(act(w,p),false);assert.equal(p.wood,50);assert.ok(placement(w,p,43,58));
 w.nextWave=Infinity;tick(w,new Map(),new Set(),.1,1001);assert.ok(q.alive);
});
test('reconstrucción valida alcance, recursos, vida y bóveda propia',()=>{
 const w=createWorld(0),p=join(w,'p','P');w.vault.hp=0;p.x=80;assert.equal(act(w,p),false);p.x=46;p.y=50;p.wood=99;assert.equal(act(w,p),false);p.wood=100;p.alive=false;assert.equal(act(w,p),false);
 const enemy=join(w,'e','E','city');enemy.x=46;enemy.y=50;assert.equal(act(w,enemy),false);assert.equal(w.vault.hp,0);
});
test('cargar guardado añade árboles y piedra cercanos una sola vez y conserva bóveda reconstruida',()=>{
 const dir=mkdtempSync(pathJoin(tmpdir(),'cerco-vault-'));
 try{
  const store=openStore(dir,0),w=store.data.worlds[0],p=join(w,'p','P');
  const nearby=w.resources.filter(r=>r.id.startsWith('forest-near-resource-'));assert.ok(nearby.some(r=>r.kind==='tree'));assert.ok(nearby.some(r=>r.kind==='rock'));
  w.vault.hp=0;p.x=46;p.y=50;assert.ok(act(w,p));const count=w.resources.length;store.save();
  const next=openStore(dir,2000).data.worlds[0];assert.equal(next.vault.hp,750);assert.equal(next.resources.length,count);
 }finally{rmSync(dir,{recursive:true,force:true});}
});
