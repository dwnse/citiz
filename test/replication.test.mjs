import {test} from 'node:test';
import assert from 'node:assert/strict';
import {DeltaEncoder,applyFrame,createEncodingContext} from '../src/replication.mjs';
import {createWorld,join,tick,snapshot} from '../src/world.mjs';
import {createServer} from '../server.mjs';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join as pathJoin} from 'node:path';
const json=value=>JSON.parse(JSON.stringify(value));

test('el lote reutiliza estructuras y población sin mezclar facciones ni conservar datos obsoletos',()=>{
 const w=createWorld(1000),a=join(w,'a','A'),b=join(w,'b','B'),c=join(w,'c','C','city'),online=new Set(['a','b','c']);
 w.walls.push({id:'shared-wall',kind:'wall',x:a.x+3,y:a.y,hp:180,communityId:a.communityId});
 snapshot(w,a.id,online,2000); // Initialize lazily created expedition geometry first.
 const batch=new WeakMap(),first=snapshot(w,a.id,online,2000,batch),second=snapshot(w,b.id,online,2000,batch),rival=snapshot(w,c.id,online,2000,batch);
 assert.deepEqual(json(first),json(snapshot(w,a.id,online,2000)));
 assert.equal(first.population,second.population);assert.notEqual(first.population,rival.population);
 assert.equal(first.walls.find(q=>q.id==='shared-wall'),second.walls.find(q=>q.id==='shared-wall'));
 w.walls.find(q=>q.id==='shared-wall').hp=30;
 assert.equal(snapshot(w,a.id,online,2000,new WeakMap()).walls.find(q=>q.id==='shared-wall').hp,30);
 assert.equal(first.walls.find(q=>q.id==='shared-wall').hp,180);
});

test('replicación conserva cambios, borrados, null, orden y altas sin mutar estados previos',()=>{
 const encoder=new DeltaEncoder();let decoded={state:null,sequence:0};
 const frames=[{version:6,players:[{id:'a',hp:100,secret:3},{id:'b',hp:80}],adventure:{elapsed:0,weather:'rain'},extra:1},
 {version:6,players:[{id:'b',hp:60},{id:'a',hp:100,secret:undefined},{id:'c',hp:30}],adventure:{elapsed:1},extra:null},
 {version:6,players:[],adventure:null},{version:6,players:[{id:'new',hp:100}],adventure:{elapsed:3}}];
 for(const state of frames){const before=json(decoded.state),frame=json(encoder.encode(state));const result=applyFrame(decoded.state,decoded.sequence,frame);assert.deepEqual(result.state,json(state));assert.deepEqual(decoded.state,before);decoded=result;}
});
test('secuencia perdida se rechaza y estado completo periódico restaura el mundo',()=>{
 const encoder=new DeltaEncoder(),state={version:6,players:[]};let decoded=applyFrame(null,0,encoder.encode(state));
 encoder.encode({...state,tick:2});const lost=encoder.encode({...state,tick:3});assert.throws(()=>applyFrame(decoded.state,decoded.sequence,lost),/Falta/);
 let full;for(let i=4;i<=100;i++)full=encoder.encode({...state,tick:i});assert.ok(full.state);decoded=applyFrame(decoded.state,decoded.sequence,full);assert.equal(decoded.state.tick,100);
});
test('estados reales reconstruidos son idénticos durante movimiento, altas y bajas de entidades',()=>{
 const w=createWorld(1000),p=join(w,'a','A');w.nextWave=1e12;const online=new Set([p.id]),encoder=new DeltaEncoder();let decoded={state:null,sequence:0},fullBytes=0,deltaBytes=0;
 for(let i=0;i<150;i++){
  if(i===20)w.walls.push({id:'test-wall',x:30,y:50,kind:'wall',hp:180,communityId:'forest'});
  if(i===35)w.walls=[];
  tick(w,new Map([[p.id,{x:1,y:0,angle:0,at:2000+i*100}]]),online,.1,2000+i*100);
  const state=snapshot(w,p.id,online,2000+i*100),frame=json(encoder.encode(state));fullBytes+=JSON.stringify(state).length;deltaBytes+=JSON.stringify(frame).length;
  decoded=applyFrame(decoded.state,decoded.sequence,frame);assert.deepEqual(decoded.state,json(state));
 }
 assert.ok(deltaBytes<fullBytes*.4,`${deltaBytes}/${fullBytes}`);
});
test('las bases son por observador y salir de visibilidad retira al rival sin revelar su inventario',()=>{
 const w=createWorld(1000),a=join(w,'a','A'),b=join(w,'b','B','city'),online=new Set(['a','b']),first=new DeltaEncoder(),second=new DeltaEncoder();
 b.wood=987;let stateA=applyFrame(null,0,json(first.encode(snapshot(w,a.id,online))));
 const stateB=applyFrame(null,0,json(second.encode(snapshot(w,b.id,online))));assert.equal(stateB.state.players.find(p=>p.id==='b').wood,987);assert.equal(stateA.state.players.some(p=>p.id==='b'),false);
 b.x=a.x+3;b.y=a.y;stateA=applyFrame(stateA.state,stateA.sequence,json(first.encode(snapshot(w,a.id,online))));const visible=stateA.state.players.find(p=>p.id==='b');assert.ok(visible);assert.equal(visible.wood,undefined);assert.equal(visible.materials,undefined);
 b.x=200;b.y=200;stateA=applyFrame(stateA.state,stateA.sequence,json(first.encode(snapshot(w,a.id,online))));assert.equal(stateA.state.players.some(p=>p.id==='b'),false);
});
test('cálculos compartidos solo duran un lote y reflejan acciones incluso sin avanzar tick',()=>{
 const w=createWorld(1000),a=join(w,'a','A'),b=join(w,'b','B'),online=new Set(['a','b']),encoders=[new DeltaEncoder(),new DeltaEncoder()];
 let decoded=[{state:null,sequence:0},{state:null,sequence:0}];
 for(let batch=0;batch<3;batch++){
  const context=createEncodingContext();b.wood=100+batch*30;
  for(const [index,player] of [a,b].entries()){
   const state=snapshot(w,player.id,online),frame=json(encoders[index].encode(state,context));
   decoded[index]=applyFrame(decoded[index].state,decoded[index].sequence,frame);assert.deepEqual(decoded[index].state,json(state));
  }
 }
 assert.equal(w.tick,0);assert.equal(decoded[1].state.players.find(p=>p.id==='b').wood,160);
});
test('HTTP permite legado y deltas; reconectar crea una base completa nueva y aislada',async()=>{
 const directory=mkdtempSync(pathJoin(tmpdir(),'cerco-delta-')),app=createServer({directory}),controllers=[];
 try{
  await new Promise(r=>app.server.listen(0,'127.0.0.1',r));const base='http://127.0.0.1:'+app.server.address().port;
  async function connect(delta,cookie){const controller=new AbortController();controllers.push(controller);const response=await fetch(base+'/api/events'+(delta?'?delta=1':''),{headers:{cookie},signal:controller.signal});const reader=response.body.getReader();let buffer='';const decoder=new TextDecoder();return async()=>{while(!buffer.includes('\n\n')){const part=await reader.read();if(part.done)throw Error('Stream cerrado');buffer+=decoder.decode(part.value,{stream:true});}const end=buffer.indexOf('\n\n'),frame=JSON.parse(buffer.slice(6,end));buffer=buffer.slice(end+2);return frame;};}
  const response=await fetch(base+'/api/join',{method:'POST',headers:{'Content-Type':'application/json'},body:'{"name":"Delta"}'}),cookie=response.headers.get('set-cookie').split(';')[0];await response.json();
  const legacy=await connect(false,cookie);assert.equal((await legacy()).version,6);
  const stream=await connect(true,cookie),full=await stream();assert.equal(full.seq,1);assert.equal(full.state.version,6);const patch=await stream();assert.equal(patch.base,1);assert.equal(applyFrame(full.state,1,patch).state.you,full.state.you);
  const restored=await connect(true,cookie),again=await restored();assert.equal(again.seq,1);assert.equal(again.state.you,full.state.you);
 }finally{for(const controller of controllers)controller.abort();await app.close();rmSync(directory,{recursive:true,force:true});}
});
