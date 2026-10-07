import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,rmSync,writeFileSync,readFileSync,existsSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join as pathJoin} from 'node:path';
import {createWorld,join,action,tick,buildRadius,CONFIG} from '../src/world.mjs';
import {solid,navigationMetrics} from '../src/navigation.mjs';
import {createServer} from '../server.mjs';

test('zombi rodea una roca y alcanza la bóveda; no recalcula cada fotograma',()=>{
  const w=createWorld();w.obstacles=[{id:'barrier',x:56,y:50,sx:1,sy:4}];
  const z={id:'walker',x:62,y:50,hp:100,level:1,attack:0};w.zombies=[z];
  let detour=false;
  for(let i=0;i<1200&&w.vault.hp===1500;i++){
    tick(w,new Map(),new Set(),1/30);
    assert.equal(solid(w,z.x,z.y),false);if(Math.abs(z.y-50)>4)detour=true;
  }
  assert.ok(detour,'debe rodear el extremo de la roca');assert.ok(w.vault.hp<1500,'debe llegar y atacar');
  assert.ok(navigationMetrics(w).searches<40,'rutas reutilizadas durante varios ticks');
});

test('presupuesto de rutas, aparición libre y núcleo destruido irreversible',()=>{
  const w=createWorld();w.zombies=Array.from({length:30},(_,i)=>({id:'z'+i,x:75,y:40+i*.2,hp:100,level:1,attack:0}));
  tick(w,new Map(),new Set(),1/30);assert.ok(navigationMetrics(w).searches<=2);
  w.walls.push({id:'spawn-wall',x:46,y:64,rot:0,hp:180});const p=join(w,'a','A');assert.equal(solid(w,p.x,p.y),false);
  p.x=46;p.y=50;p.wood=100;w.vault.hp=0;w.drops=[];
  assert.equal(action(w,p,{type:'interact',seq:1}),false);assert.equal(w.vault.hp,0);assert.equal(p.wood,100);
});

test('roca bloquea disparo y construcción, sin gastar al rechazar',()=>{
  const w=createWorld(),p=join(w,'a','A');p.x=62;p.y=57;
  w.zombies=[{id:'z',x:70,y:57,hp:100}];
  assert.ok(action(w,p,{type:'shoot',angle:0,seq:1}));assert.equal(w.zombies[0].hp,100);
  assert.equal(action(w,p,{type:'build',x:64,y:56,seq:2}),false);assert.equal(p.wood,100);
});

test('mejora amplía construcciones, cobra una vez y no supera el doble del radio',()=>{
  const w=createWorld(),p=join(w,'a','A');p.wood=1000;p.x=30;p.y=54;
  assert.equal(action(w,p,{type:'build',x:30,y:50,seq:1}),false);
  assert.equal(action(w,p,{type:'upgrade',seq:2}),false,'requiere cercanía');
  p.x=46;p.y=50;assert.equal(action(w,p,{type:'upgrade',seq:3}),true);
  assert.equal(action(w,p,{type:'upgrade',seq:3}),false,'repetición no cobra');assert.equal(p.wood,940);
  p.x=30;p.y=54;assert.equal(action(w,p,{type:'build',x:30,y:50,seq:4}),true);
  p.x=46;p.y=50;assert.ok(action(w,p,{type:'upgrade',seq:5}));assert.ok(action(w,p,{type:'upgrade',seq:6}));
  assert.equal(buildRadius(w),36);const remaining=p.wood;assert.equal(action(w,p,{type:'upgrade',seq:7}),false);assert.equal(p.wood,remaining);
});

function fixture(){const directory=mkdtempSync(pathJoin(tmpdir(),'cerco-expansion-'));return {directory,cleanup(){rmSync(directory,{recursive:true,force:true});}};}
async function listen(app){await new Promise(r=>app.server.listen(0,'127.0.0.1',r));return `http://127.0.0.1:${app.server.address().port}`;}
async function post(base,path,body,cookie){const r=await fetch(base+path,{method:'POST',headers:{'Content-Type':'application/json',...(cookie?{cookie}:{})},body:JSON.stringify(body)});return {status:r.status,data:await r.json(),cookie:r.headers.get('set-cookie')?.split(';')[0]};}

test('dos mundos aíslan identidades, plazas y estados y persisten en un reinicio',async()=>{
  const f=fixture();let app=createServer({directory:f.directory});
  try{
    let base=await listen(app);const original=app.world.id;
    const created=await post(base,'/api/worlds',{name:'Otro bosque'});assert.equal(created.status,201);const other=created.data.world.id;
    const a=await post(base,'/api/join',{name:'A',worldId:original});
    const b=await post(base,'/api/join',{name:'B',worldId:other});
    assert.equal(Object.keys(app.worlds[0].players).length,1);assert.equal(Object.keys(app.worlds[1].players).length,1);
    assert.equal((await post(base,'/api/join',{key:a.data.key,worldId:other})).status,403);
    assert.equal((await post(base,'/api/join',{worldId:'unknown'})).status,404);
    app.worlds[0].vault.hp=75;app.worlds[1].vault.hp=900;app.worlds[1].vault.upgrades=2;
    await app.close();app=createServer({directory:f.directory});base=await listen(app);
    const back=await post(base,'/api/join',{key:b.data.key,worldId:other});assert.equal(back.data.id,b.data.id);
    assert.equal(app.worlds.length,2);assert.equal(app.worlds[0].vault.hp,75);assert.equal(app.worlds[1].vault.hp,900);assert.equal(buildRadius(app.worlds[1]),30);
    const listing=await fetch(base+'/api/worlds').then(r=>r.json());assert.equal(listing.worlds[1].name,'Otro bosque');
  }finally{await app.close();f.cleanup();}
});

test('migración v1 conserva clave, fecha, inventario y construcciones con backup exacto',async()=>{
  const f=fixture();let app;
  try{
    const world=createWorld(Date.now()-100000),p=join(world,'legacy-player','Veterano');world.version=1;delete world.obstacles;delete world.name;
    p.wood=67;p.seq=91;world.walls=[{id:'legacy-wall',x:43,y:57,rot:0,hp:130,maxHp:180}];
    const raw=JSON.stringify({version:1,world,accounts:{'legacy-key':p.id}});writeFileSync(f.directory+'/world.json',raw);
    app=createServer({directory:f.directory});const base=await listen(app);
    const r=await post(base,'/api/join',{key:'legacy-key'});assert.equal(r.data.id,p.id);assert.equal(r.data.seq,91);
    assert.equal(app.world.players[p.id].wood,67);assert.equal(app.world.startedAt,world.startedAt);assert.equal(app.world.walls[0].id,'legacy-wall');assert.deepEqual(app.world.obstacles,[]);
    assert.equal(readFileSync(f.directory+'/world.json.v1.bak','utf8'),raw);
    const written=JSON.parse(readFileSync(f.directory+'/world.json','utf8'));assert.equal(written.version,6);assert.equal(written.worlds.length,1);assert.equal(existsSync(f.directory+'/world.json.tmp'),false);
  }finally{if(app)await app.close();f.cleanup();}
});

test('producción bloquea crear mundos y datos JSON inválidos se rechazan',async()=>{
  const f=fixture(),app=createServer({directory:f.directory,mode:'production'});
  try{const base=await listen(app);assert.equal((await post(base,'/api/worlds',{})).status,403);assert.equal((await post(base,'/api/join',null)).status,400);}
  finally{await app.close();f.cleanup();}
});

test('ocho partidas terminadas no bloquean crear otra ni pierden guardados',async()=>{
 const f=fixture();let app=createServer({directory:f.directory});
 try{
  let base=await listen(app);
  const first=await post(base,'/api/join',{name:'Veterano'});
  while(app.worlds.length<8)assert.equal((await post(base,'/api/worlds',{})).status,201);
  assert.equal((await post(base,'/api/worlds',{})).status,409,'ocho activas mantienen el límite');
  for(const w of app.worlds)w.phase='defeat';
  const saved=JSON.stringify(app.worlds);
  const created=await post(base,'/api/worlds',{name:'Volver a jugar'});
  assert.equal(created.status,201);
  assert.equal(app.worlds.length,9);
  assert.equal(JSON.stringify(app.worlds.slice(0,8)),saved);
  const entered=await post(base,'/api/join',{worldId:created.data.world.id,accountKey:first.data.key,name:'Veterano'});
  assert.equal(entered.status,200);
  assert.equal(app.worlds[8].players[entered.data.id].alive,true);
  await app.close();app=createServer({directory:f.directory});base=await listen(app);
  assert.equal(app.worlds.length,9);
  assert.equal((await post(base,'/api/join',{key:entered.data.key,worldId:created.data.world.id})).data.id,entered.data.id);
  assert.equal(app.worlds[0].players[first.data.id].id,first.data.id);
 }finally{await app.close();f.cleanup();}
});

test('un mundo sin clientes conserva el núcleo frente a infectados y respeta la caducidad',async()=>{
 const f=fixture();let now=Date.now();const app=createServer({directory:f.directory,clock:()=>now});
 try{
  await listen(app);
  const w=app.world,p=join(w,'offline','Offline');
  w.zombies=[{id:'near-core',x:54,y:50,hp:100,maxHp:100,level:1,attack:0,communityId:'forest'}];
  const saved=JSON.stringify({hp:w.vault.hp,zombies:w.zombies,tick:w.tick});
  await new Promise(r=>setTimeout(r,180));
  assert.equal(JSON.stringify({hp:w.vault.hp,zombies:w.zombies,tick:w.tick}),saved);
  now=w.startedAt+CONFIG.duration+1;
  await new Promise(r=>setTimeout(r,100));
  assert.equal(w.phase,'expired');
  assert.equal(w.vault.hp,JSON.parse(saved).hp);
  assert.equal(p.alive,true);
 }finally{await app.close();f.cleanup();}
});


