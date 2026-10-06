import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createWorld,join,action,snapshot,tick} from '../src/world.mjs';
import {initializeAdventure,adventureTick} from '../src/adventure.mjs';
import {initializeInteriors,campaignStage,expeditionsTick} from '../src/expeditions.mjs';
import {findPath,solid} from '../src/navigation.mjs';
import {openStore} from '../src/storage.mjs';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join as pathJoin} from 'node:path';
function setup(kind='hospital'){
 const w=createWorld(1000),p=join(w,'a','A'),online=new Set(['a']),a=initializeAdventure(w),site=a.sites.find(s=>s.kind===kind&&s.interior);
 assert.ok(site);p.x=site.interior.entry.x;p.y=site.interior.entry.y;
 const act=(time=2000)=>action(w,p,{type:'expedition',seq:p.seq+1},time,online);
 return {w,p,a,site,online,act};
}
test('interiores nuevos tienen acceso entre salas y recursos fuera de sus rutas',()=>{
 const {w,p,site,online}=setup();snapshot(w,p.id,online,2000);
 const path=findPath(w,site.interior.entry,site.interior.objective,1,2400);
 assert.ok(path.length);assert.ok(path.every(q=>!solid(w,q.x,q.y)));
 for(const s of w.adventure.sites.filter(s=>s.interior))assert.equal(w.resources.some(r=>Math.abs(r.x-s.x)<6&&Math.abs(r.y-s.y)<6),false);
 const n=w.obstacles.length;initializeInteriors(w,w.adventure);assert.equal(w.obstacles.length,n);
});
test('migración omite recintos ocupados y no elimina construcciones ni recursos',()=>{
 const w=createWorld(1000),a={sites:[{id:'test',kind:'hospital',name:'Hospital',x:25,y:80}]};
 w.resources=[{id:'keep',x:25,y:80,kind:'tree',hits:5}];const before=structuredClone(w.resources);initializeInteriors(w,a);
 assert.equal(a.sites[0].interior,undefined);assert.deepEqual(w.resources,before);assert.equal(a.interiorsVersion,1);
});
test('hospital exige combate y presencia; recompensa e informe solo una vez',()=>{
 const {w,p,a,site,act,online}=setup();assert.equal(act(),true);assert.equal(p.cargo,undefined);assert.equal(w.zombies.length,2);
 assert.equal(act(),false);assert.equal(w.zombies.length,2);
 p.x=site.interior.objective.x;p.y=site.interior.objective.y;expeditionsTick(w,online,30);assert.equal(site.encounter.progress,0);
 w.zombies=[];expeditionsTick(w,new Set(),30);assert.equal(site.encounter.progress,0);
 expeditionsTick(w,online,12);assert.equal(site.encounter.status,'ready');assert.equal(act(),true);assert.equal(p.medical,2);assert.equal(p.cargo.kind,'hospital');
 assert.equal(act(),false);assert.equal(p.medical,2);assert.equal(a.expeditionHistory.length,1);
});
test('laboratorio protege propiedad y visión, aumenta amenaza con campaña y caduca',()=>{
 const {w,p,a,site,act,online}=setup('laboratory');assert.equal(campaignStage(w,1000+28*86400000).threat,6);
 assert.equal(act(1000+11*86400000),true);assert.equal(site.encounter.remaining,4);assert.equal(site.encounter.phase,'Guerra');
 const rival=join(w,'r','R','city');rival.x=p.x;rival.y=p.y;
 assert.equal(action(w,rival,{type:'expedition',seq:1},2000,new Set(['a','r'])),false);
 w.zombies=[];p.x=site.interior.objective.x;p.y=site.interior.objective.y+1;
 w.obstacles.push({id:'closed',x:p.x,y:p.y-.5,sx:1,sy:.25});expeditionsTick(w,online,30);assert.equal(site.encounter.progress,0);
 a.elapsed=181;expeditionsTick(w,online,.1);assert.equal(site.encounter,null);assert.equal(p.cargo,undefined);
});
test('guardado conserva progreso; desconexión congela el reloj del encuentro',()=>{
 const {w,p,a,site,act,online}=setup();act();w.zombies=[];p.x=site.interior.objective.x;p.y=site.interior.objective.y;
 expeditionsTick(w,online,5);const elapsed=a.elapsed;adventureTick(w,new Set(),100,9000,new Map());assert.equal(a.elapsed,elapsed);assert.equal(site.encounter.progress,5);
 const directory=mkdtempSync(pathJoin(tmpdir(),'cerco-interiors-'));
 try{const store=openStore(directory,2000);store.data.worlds=[w];store.save();const restored=openStore(directory,3000).data.worlds[0];const s=restored.adventure.sites.find(q=>q.id===site.id);assert.equal(s.encounter.progress,5);assert.equal(s.encounter.communityId,p.communityId);assert.deepEqual(s.interior,site.interior);}finally{rmSync(directory,{recursive:true,force:true});}
});
test('cupo de infectados rechaza el inicio sin cambios y pausa congela encuentro',()=>{
 const {w,p,a,site,act,online}=setup();
 w.zombies=Array.from({length:96},(_,i)=>({id:'z'+i,x:100,y:100,hp:52}));
 assert.equal(act(),false);assert.equal(site.encounter,undefined);assert.equal(w.zombies.length,96);
 w.zombies=[];assert.equal(act(),true);const enemies=structuredClone(w.zombies);
 assert.equal(action(w,p,{type:'pause',seq:p.seq+1},2100,online),true);tick(w,new Map(),online,10,12100);
 assert.equal(a.elapsed,0);assert.equal(site.encounter.progress,0);assert.deepEqual(w.zombies,enemies);
});
