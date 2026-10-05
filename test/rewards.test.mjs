import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,rmSync,writeFileSync,readFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join as pathJoin} from 'node:path';
import {createWorld,join,action,tick} from '../src/world.mjs';
import {openStore} from '../src/storage.mjs';
import {createServer} from '../server.mjs';
import {settleRewards} from '../src/rewards.mjs';
import {SPELLS} from '../src/story.mjs';

test('v5 migra a v6 con copia exacta; materiales antiguos y cuentas se conservan',()=>{
 const directory=mkdtempSync(pathJoin(tmpdir(),'cerco-v6-'));
 try{
  const w=createWorld(1000),p=join(w,'a','A');w.version=5;p.wood=173;
  const raw=JSON.stringify({version:5,worlds:[w],accounts:{key:{id:p.id,worldId:w.id}}});writeFileSync(directory+'/world.json',raw);
  const store=openStore(directory,2000);assert.equal(store.data.version,6);assert.equal(store.data.worlds[0].version,6);assert.equal(store.data.worlds[0].players.a.materials.reclaimed,173);
  assert.equal(readFileSync(directory+'/world.json.v5.bak','utf8'),raw);store.save();const restored=openStore(directory,3000);assert.equal(restored.data.accounts.key.profileId,'a');assert.equal(restored.data.profiles.a.coins,0);assert.equal(restored.data.worlds[0].players.a.wood,173);
 }finally{rmSync(directory,{recursive:true,force:true});}
});
test('cura rechaza rivales supervivientes, autoría ajena y vencimiento real incluso pausado',()=>{
 const w=createWorld(1000),p=join(w,'a','A'),rival=join(w,'b','B','city');p.sample=true;w.story.communities.forest.fragments=SPELLS.map(s=>s.id);w.communities[0].research=3;
 w.story.patient={defeated:true,defeatedBy:'forest'};w.walls=[{id:'lab',kind:'laboratory',communityId:'forest',x:p.x+2,y:p.y,hp:300}];
 const act=now=>action(w,p,{type:'use',id:'lab',seq:p.seq+1},now);
 assert.equal(act(2000),false);assert.equal(p.sample,true);w.communities.find(c=>c.id==='city').eliminated=true;rival.alive=false;
 w.story.patient.defeatedBy='city';assert.equal(act(2000),false);assert.equal(w.communities[0].research,3);
 w.story.patient.defeatedBy='forest';assert.equal(act(1000+30*86400000),false);assert.equal(w.phase,'expired');
 w.phase='active';w.pausedBy=p.id;w.pauseAt=2000;tick(w,new Map(),new Set([p.id]),.1,1000+30*86400000);assert.equal(w.phase,'expired');
});
test('recompensas son únicas por cuenta y mundo; no se pagan al expirar o sin contribución',()=>{
 const w=createWorld(1000),p=join(w,'a','A'),ally=join(w,'b','B');p.kills=1;w.phase='victory';w.winner='forest';w.completedAt=2000;
 const data={worlds:[w],accounts:{one:{id:p.id,worldId:w.id},alias:{id:p.id,worldId:w.id},other:{id:ally.id,worldId:w.id}}};
 settleRewards(data);settleRewards(data);assert.equal(data.profiles.a.coins,12);assert.equal(data.profiles.a.seals,1);assert.equal(data.profiles.b.coins,0);assert.equal(Object.keys(data.profiles.a.rewards).length,1);
 const late=structuredClone(w);late.id='late';late.completedAt=1000+30*86400000;data.worlds.push(late);data.accounts.late={id:'a',profileId:'a',worldId:'late'};settleRewards(data);assert.equal(data.profiles.a.coins,12);
});
test('cuenta conserva cosméticos en otro mundo sin trasladar materiales ni duplicar plaza o premio',async()=>{
 const directory=mkdtempSync(pathJoin(tmpdir(),'cerco-account-'));let app=createServer({directory,clock:()=>2000});
 try{
  await new Promise(r=>app.server.listen(0,'127.0.0.1',r));const base='http://127.0.0.1:'+app.server.address().port;
  const post=async(path,body)=>{const r=await fetch(base+path,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});assert.ok(r.ok);return r.json();};
  const first=await post('/api/join',{name:'A'});const p=app.world.players[first.id];p.wood=900;p.kills=1;app.world.phase='victory';app.world.winner='forest';app.world.completedAt=2000;app.save();
  const created=await post('/api/worlds',{});const second=await post('/api/join',{worldId:created.world.id,accountKey:first.key,name:'A2'});
  assert.notEqual(first.id,second.id);assert.equal(app.worlds[1].players[second.id].wood,100);
  const replay=await post('/api/join',{worldId:created.world.id,accountKey:first.key,name:'Repeat',communityId:'city'});assert.equal(replay.id,second.id);assert.equal(replay.key,second.key);assert.equal(Object.keys(app.worlds[1].players).length,1);
  await app.close();app=null;const saved=openStore(directory,3000).data;const profile=saved.accounts[second.key].profileId;assert.equal(saved.profiles[profile].coins,12);settleRewards(saved);assert.equal(saved.profiles[profile].seals,1);
 }finally{if(app)await app.close();rmSync(directory,{recursive:true,force:true});}
});

test('si cae la comunidad que mató al origen, el sello permite un nuevo enfrentamiento',()=>{
 const w=createWorld(1000),p=join(w,'a','A'),rival=join(w,'b','B','city');p.intro=true;w.story.patient={id:'old',defeated:true,defeatedBy:'city'};rival.sample=true;
 w.communities.find(c=>c.id==='city').eliminated=true;rival.alive=false;w.drops.push({id:'old-sample',sample:true,x:105,y:105});
 tick(w,new Map(),new Set([p.id]),.1,2000);assert.equal(w.story.patient,undefined);assert.equal(rival.sample,false);assert.equal(w.drops.some(d=>d.sample),false);
});
