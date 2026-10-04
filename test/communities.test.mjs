import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,rmSync,writeFileSync,readFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join as pathJoin} from 'node:path';
import {createWorld,join,action,tick,snapshot} from '../src/world.mjs';
import {core,capacity,siegeStatus,checkElimination} from '../src/communities.mjs';
import {openStore} from '../src/storage.mjs';
import {createServer} from '../server.mjs';

test('cuatro comunidades: 40 plazas permanentes, límite 10 y reconexión sin cambiar facción',()=>{
  const w=createWorld();
  for(const c of w.communities)for(let i=0;i<10;i++)join(w,c.id+i,c.id+i,c.id);
  assert.equal(Object.keys(w.players).length,40);assert.equal(capacity(w),40);
  assert.throws(()=>join(w,'extra','Extra','forest'));
  const p=join(w,'forest0','Otro nombre','city');assert.equal(p.communityId,'forest');assert.equal(Object.keys(w.players).length,40);
  const isolated=createWorld();for(let i=0;i<10;i++)join(isolated,'p'+i,'p','city');
  assert.throws(()=>join(isolated,'overflow','x','city'));assert.ok(join(isolated,'mountain','x','mountain'));
});

test('permisos de construcción: rival no construye, repara, desmantela ni mejora otra base',()=>{
  const w=createWorld(),a=join(w,'a','A','forest'),b=join(w,'b','B','city');a.x=43;a.y=54;
  assert.ok(action(w,a,{type:'build',x:43,y:58,seq:1}));const wall=w.walls[0];wall.hp=100;
  b.x=43;b.y=56;const before=b.wood;
  assert.equal(action(w,b,{type:'repair',id:wall.id,seq:1}),false);
  assert.equal(action(w,b,{type:'dismantle',id:wall.id,seq:2}),false);
  assert.equal(action(w,b,{type:'build',x:40,y:55,seq:3}),false);
  b.x=46;b.y=50;assert.equal(action(w,b,{type:'upgrade',seq:4}),false);assert.equal(b.wood,before);assert.equal(wall.hp,100);
  assert.ok(action(w,a,{type:'repair',id:wall.id,seq:2}));assert.equal(wall.hp,165);
});

test('asedio: reloj, protección fuera de ventana y offline, daño, robo sin duplicación',()=>{
  const w=createWorld(0),a=join(w,'a','A'),b=join(w,'b','B','city'),online=new Set(['a','b']);
  a.x=154;a.y=50;b.x=158;b.y=56;
  assert.equal(siegeStatus(w,119999).active,false);assert.equal(siegeStatus(w,120000).active,true);assert.equal(siegeStatus(w,210000).active,false);
  assert.ok(action(w,a,{type:'shoot',angle:0,seq:1},119999,online));assert.equal(core(w,b).hp,1500);
  a.cooldown=0;action(w,a,{type:'shoot',angle:0,seq:2},120000,new Set(['a']));assert.equal(core(w,b).hp,1500);
  a.cooldown=0;action(w,a,{type:'shoot',angle:0,seq:3},120000,online);assert.equal(core(w,b).hp,1466);
  a.x=155;const wood=a.wood,stock=w.communities[2].stock;
  assert.ok(action(w,a,{type:'interact',seq:4},120000,online));assert.equal(a.wood,wood+20);assert.equal(w.communities[2].stock,stock-20);
  assert.equal(action(w,a,{type:'interact',seq:4},120000,online),false);
  assert.equal(action(w,a,{type:'interact',seq:5},120001,online),false);assert.equal(a.wood,wood+20);
});

test('destruir núcleo y matar último miembro elimina solo esa comunidad, sin victoria automática',()=>{
  const w=createWorld(0),a=join(w,'a','A'),b=join(w,'b','B','city'),online=new Set(['a','b']);
  a.x=154;a.y=50;b.x=158;b.y=56;core(w,b).hp=30;
  action(w,a,{type:'shoot',angle:0,seq:1},120000,online);assert.equal(core(w,b).hp,0);
  a.x=154;a.y=56;a.cooldown=0;b.hp=10;b.armor=0;
  action(w,a,{type:'shoot',angle:0,seq:2},120001,online);assert.equal(b.alive,false);
  tick(w,new Map(),online,1/30,130000);assert.equal(b.alive,false);assert.equal(w.communities[2].eliminated,true);
  assert.equal(w.communities[0].eliminated,false);assert.equal(w.phase,'active');assert.throws(()=>join(w,'late','Late','city'));
  a.alive=false;core(w,a).hp=0;checkElimination(w);assert.equal(w.phase,'defeat');
});

test('aliados bloquean fuego amigo y los rivales lejanos no filtran inventario ni posición',()=>{
  const w=createWorld(0),a=join(w,'a','A'),ally=join(w,'ally','Ally'),enemy=join(w,'enemy','Enemy','city');
  a.x=40;a.y=40;ally.x=44;ally.y=40;
  action(w,a,{type:'shoot',angle:0,seq:1},120000,new Set(['a','ally','enemy']));assert.equal(ally.hp,100);
  let s=snapshot(w,'a',new Set(['a','enemy']),120000);assert.equal(s.players.some(p=>p.id==='enemy'),false);
  enemy.x=60;enemy.y=40;s=snapshot(w,'a',new Set(['a','enemy']),120000);
  const visible=s.players.find(p=>p.id==='enemy');assert.ok(visible);assert.equal('wood' in visible,false);assert.equal('reserve' in visible,false);
});

test('migración v2 conserva base, muros y cuenta en comunidad de legado; v3 restaura alias de núcleo',()=>{
  const dir=mkdtempSync(pathJoin(tmpdir(),'cerco-v3-'));
  try{
    const w=createWorld();join(w,'old','Old');w.vault.hp=789;w.walls=[{id:'wall',x:40,y:40,hp:150,rot:0}];
    delete w.communities;delete w.rules;delete w.size;w.version=2;delete w.players.old.communityId;
    const raw=JSON.stringify({version:2,worlds:[w],accounts:{oldkey:{id:'old',worldId:w.id}}});writeFileSync(dir+'/world.json',raw);
    let store=openStore(dir,Date.now()),m=store.data.worlds[0];assert.equal(capacity(m),10);assert.equal(m.players.old.communityId,'forest');assert.equal(m.walls[0].communityId,'forest');assert.equal(m.vault.hp,789);assert.equal(m.legacy,true);
    assert.equal(readFileSync(dir+'/world.json.v2.bak','utf8'),raw);m.communities[0].stock=17;store.save();
    store=openStore(dir,Date.now());m=store.data.worlds[0];assert.equal(m.communities[0].stock,17);assert.equal(m.vault,m.communities[0].vault);assert.equal(store.data.accounts.oldkey.id,'old');
  }finally{rmSync(dir,{recursive:true,force:true});}
});

test('última plaza concurrente en HTTP, reconexión conserva facción y 40 es el cupo anunciado',async()=>{
  const dir=mkdtempSync(pathJoin(tmpdir(),'cerco-slots-')),app=createServer({directory:dir});
  try{
    await new Promise(r=>app.server.listen(0,'127.0.0.1',r));const base=`http://127.0.0.1:${app.server.address().port}`;
    const post=async body=>{const r=await fetch(base+'/api/join',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});return {status:r.status,data:await r.json()};};
    let first;for(let i=0;i<9;i++){const r=await post({name:'p'+i,communityId:'mountain'});first||=r.data;}
    const results=await Promise.all([post({name:'lastA',communityId:'mountain'}),post({name:'lastB',communityId:'mountain'})]);assert.equal(results.filter(r=>r.status===200).length,1);
    const back=await post({key:first.key,communityId:'city'});assert.equal(back.data.communityId,'mountain');assert.equal(back.data.id,first.id);
    const directory=await fetch(base+'/api/worlds').then(r=>r.json());assert.equal(directory.worlds[0].capacity,40);assert.equal(directory.worlds[0].communities.find(c=>c.id==='mountain').members,10);
  }finally{await app.close();rmSync(dir,{recursive:true,force:true});}
});
