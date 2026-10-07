import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join as pathJoin} from 'node:path';
import {createWorld,join,action,tick,spawnWave,CONFIG} from '../src/world.mjs';
import {createServer} from '../server.mjs';
test('construcción cobra una vez, valida corredor, alcance y datos inválidos',()=>{
 const w=createWorld(),p=join(w,'a','A');p.x=43;p.y=54;
 assert.equal(action(w,p,{type:'build',x:43,y:58,seq:1}),true);
 assert.equal(p.wood,80);assert.equal(w.walls.length,1);
 assert.equal(action(w,p,{type:'build',x:43,y:58,seq:1}),false);
 assert.equal(action(w,p,{type:'build',x:50,y:57,seq:2}),false);
 assert.equal(action(w,p,{type:'build',x:90,y:90,seq:3}),false);
 assert.equal(action(w,p,{type:'build',x:null,y:'bad',seq:4}),false);
 assert.equal(p.wood,80);
});
test('pistola: impacto, cadencia, recarga, muro bloquea disparo',()=>{
 const w=createWorld(),p=join(w,'a','A');p.x=40;p.y=40;
 w.zombies.push({id:'z',x:45,y:40,hp:60,maxHp:60});
 assert.ok(action(w,p,{type:'shoot',angle:0,seq:1}));assert.equal(w.zombies[0].hp,26);
 assert.equal(action(w,p,{type:'shoot',angle:0,seq:2}),false);assert.equal(p.ammo,11);
 p.cooldown=0;w.walls.push({id:'wall',x:42,y:40,rot:1,hp:180});action(w,p,{type:'shoot',angle:0,seq:3});assert.equal(w.zombies[0].hp,26);
 action(w,p,{type:'reload',seq:4});w.zombies=[];tick(w,new Map(),new Set(),1.5);assert.equal(p.ammo,12);assert.equal(p.reserve,58);
});
test('movimiento limitado, desconectado inmóvil y puerta pública transitable',()=>{
 const w=createWorld(),p=join(w,'a','A'),now=Date.now();const inputs=new Map([['a',{x:1000,y:0,at:now}]]);
 tick(w,inputs,new Set(),1,now);assert.equal(p.x,46);
 tick(w,inputs,new Set(['a']),1,now);assert.ok(p.x<=53);assert.equal(p.hp,100);
});
test('caída de bóveda elimina sin reaparición, plazo sobrevive al calendario',()=>{
 const w=createWorld(),p=join(w,'a','A');p.x=55;p.y=50;p.hp=1;p.armor=0;w.vault.hp=0;
 w.zombies.push({id:'z',x:55,y:51,hp:50,level:1,attack:0});
 tick(w,new Map(),new Set(['a']),.1);assert.equal(p.alive,false);assert.equal(w.phase,'defeat');
 tick(w,new Map(),new Set(['a']),10,Date.now()+20000);assert.equal(p.alive,false);
 const expired=createWorld(0);join(expired,'b','B');tick(expired,new Map(),new Set(),.1,CONFIG.duration+1);assert.equal(expired.phase,'expired');assert.throws(()=>join(expired,'c','C'));
});
test('infectado alcanza la bóveda y puede destruirla sin atravesar la colisión',()=>{
 const w=createWorld();w.vault.hp=24;w.zombies.push({id:'z',x:55,y:50,hp:60,level:1,attack:0});
 for(let i=0;i<150;i++)tick(w,new Map(),new Set(),1/30);
 assert.equal(w.vault.hp,0);assert.ok(Math.hypot(w.zombies[0].x-50,w.zombies[0].y-50)>=2.8);
});
test('oleadas, jefe y reaparición con coste recuperable',()=>{
 const w=createWorld(),p=join(w,'a','A');spawnWave(w,1);const first=w.zombies[0].maxHp;w.zombies=[];spawnWave(w,2);assert.ok(w.zombies[0].maxHp>first);w.zombies=[];spawnWave(w,3);assert.equal(w.zombies.filter(z=>z.boss).length,1);
 w.zombies=[];p.alive=false;p.respawn=0;tick(w,new Map(),new Set(),.1);assert.equal(p.alive,true);assert.equal(p.wood,80);
});
test('dos clientes HTTP/SSE, autoridad, reconexión y reinicio persistente',async()=>{
 const directory=mkdtempSync(pathJoin(tmpdir(),'cerco-test-'));let app;const controllers=[];
 async function start(){app=createServer({directory});await new Promise(r=>app.server.listen(0,'127.0.0.1',r));return `http://127.0.0.1:${app.server.address().port}`;}
 let base=await start();
 async function post(route,data,cookie){const r=await fetch(base+route,{method:'POST',headers:{'Content-Type':'application/json',...(cookie?{cookie}:{})},body:JSON.stringify(data)});return {status:r.status,data:await r.json(),cookie:r.headers.get('set-cookie')?.split(';')[0]};}
 async function connect(cookie){const c=new AbortController();controllers.push(c);const r=await fetch(base+'/api/events',{headers:{cookie},signal:c.signal});return {reader:r.body.getReader(),c};}
 const eventBuffers=new WeakMap();
 async function state(reader){
  let pending=eventBuffers.get(reader)||{text:'',decoder:new TextDecoder()};
  while(!pending.text.includes('\n\n')){
   const r=await reader.read();if(r.done)throw Error('SSE ended before a complete event');
   pending.text+=pending.decoder.decode(r.value,{stream:true});
  }
  const end=pending.text.indexOf('\n\n'),event=pending.text.slice(0,end);
  pending.text=pending.text.slice(end+2);eventBuffers.set(reader,pending);
  return JSON.parse(event.split('data: ')[1]);
 }
 try{
 const a=await post('/api/join',{name:'Alpha'}),b=await post('/api/join',{name:'Bravo'});assert.notEqual(a.data.id,b.data.id);
 assert.equal((await post('/api/action',{type:'craft',seq:1},a.cookie)).status,401);
 const sa=await connect(a.cookie),sb=await connect(b.cookie);const initialA=await state(sa.reader);await state(sb.reader);assert.equal(initialA.players.length,2);
 await post('/api/input',{x:1,y:0,angle:0},a.cookie);await new Promise(r=>setTimeout(r,150));assert.ok(app.world.players[a.data.id].x>46);
 const before=app.world.players[a.data.id].wood;await post('/api/action',{type:'craft',seq:1,wood:99999,hp:99999},a.cookie);assert.equal(app.world.players[a.data.id].wood,before-15);assert.equal(app.world.players[a.data.id].hp,100);
 await post('/api/action',{type:'craft',seq:1},a.cookie);assert.equal(app.world.players[a.data.id].wood,before-15);
 const built=await post('/api/action',{type:'build',x:44,y:60,seq:2},a.cookie);assert.ok(built.data.ok);
 let observed;for(let i=0;i<12;i++){observed=await state(sb.reader);if(observed.walls.length===1)break;}
 assert.equal(observed.walls.length,1);assert.equal(observed.players.find(p=>p.id===a.data.id).wood,before-35);
 const shooter=app.world.players[a.data.id];app.world.zombies.push({id:'integration-target',x:shooter.x+4,y:shooter.y,hp:100,maxHp:100,level:1,attack:0});
 const shot=await post('/api/action',{type:'shoot',angle:0,seq:3},a.cookie);assert.ok(shot.data.ok);
 for(let i=0;i<12;i++){observed=await state(sb.reader);if(observed.zombies.some(z=>z.id==='integration-target'&&z.hp===66))break;}
 assert.equal(observed.zombies.find(z=>z.id==='integration-target').hp,66);
 assert.equal((await post('/api/input',{x:'NaN',y:0,angle:0},a.cookie)).status,400);
 sa.c.abort();sb.c.abort();await new Promise(r=>setTimeout(r,60));
 const stored=app.world.players[a.data.id].wood,startedAt=app.world.startedAt;await app.close();
 base=await start();const reconnect=await post('/api/join',{key:a.data.key});assert.equal(reconnect.data.id,a.data.id);assert.equal(app.world.players[a.data.id].wood,stored);assert.equal(app.world.startedAt,startedAt);assert.equal(Object.keys(app.world.players).length,2);assert.equal(app.world.walls.length,1);assert.equal(reconnect.data.seq,3);
 const stream=await connect(reconnect.cookie);const snap=await state(stream.reader);assert.equal(snap.you,a.data.id);assert.equal(snap.players.find(p=>p.id===a.data.id).wood,stored);stream.c.abort();
 }finally{for(const c of controllers)c.abort();if(app)await app.close();rmSync(directory,{recursive:true,force:true});}
});
