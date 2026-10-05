import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,readFileSync,writeFileSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join as pathJoin} from 'node:path';
import {createWorld,join,action,tick} from '../src/world.mjs';
import {STRUCTURES,structuresTick} from '../src/structures.mjs';
import {solid} from '../src/navigation.mjs';
import {openStore} from '../src/storage.mjs';
function fixture(){const w=createWorld(0),p=join(w,'a','A');w.nextWave=Infinity;p.wood=1000;return {w,p};}
function act(w,p,type,extra={},now=100){return action(w,p,{type,seq:p.seq+1,...extra},now);}

test('recarga repetible: diez cargadores con paso fraccionario y reserva parcial final',()=>{
 const {w,p}=fixture();p.reserve=123;p.ammo=0;
 for(let cycle=0;cycle<10;cycle++){
  assert.ok(act(w,p,'reload'));assert.equal(act(w,p,'reload'),false);
  for(let frame=0;frame<43;frame++)tick(w,new Map(),new Set(),1/30,1000+frame);
  assert.equal(p.reload,0);assert.equal(p.ammo,12);assert.equal(p.reserve,123-(cycle+1)*12);
  for(let i=0;i<12;i++){p.cooldown=0;assert.ok(act(w,p,'shoot',{angle:0}));}
 }
 assert.ok(act(w,p,'reload'));tick(w,new Map(),new Set(),1.5,2000);
 assert.equal(p.ammo,3);assert.equal(p.reserve,0);assert.equal(p.reload,0);assert.equal(act(w,p,'reload'),false);
 p.ammo=0;p.reserve=12;p.reload=-0.0001;assert.ok(act(w,p,'reload'));
});

test('ocho estructuras cobran su coste y rechazan tipos desconocidos, solapamientos y duplicados',()=>{
 for(const [kind,d] of Object.entries(STRUCTURES)){
  const {w,p}=fixture(),before=p.wood;
  assert.ok(act(w,p,'build',{kind,x:43,y:58}));assert.equal(p.wood,before-d.cost);assert.equal(w.walls[0].maxHp,d.hp);
  assert.equal(action(w,p,{type:'build',kind,x:43,y:58,seq:p.seq}),false);
  assert.equal(act(w,p,'build',{kind,x:43,y:58}),false);assert.equal(p.wood,before-d.cost);
 }
 const {w,p}=fixture();for(const kind of ['free_money','toString','constructor','__proto__'])assert.equal(act(w,p,'build',{kind,x:43,y:58}),false);assert.equal(p.wood,1000);
});

test('piezas contiguas encajan sin hueco; variantes giradas y colocación RTS dentro del territorio',()=>{
 const {w,p}=fixture();
 assert.ok(act(w,p,'build',{kind:'wall',x:43,y:58}));
 assert.ok(act(w,p,'build',{kind:'gate',x:39.8,y:58}));
 assert.equal(solid(w,41.4,58,0.1),true);
 assert.equal(act(w,p,'build',{kind:'wall',x:41,y:58}),false);
 assert.ok(act(w,p,'build',{kind:'wall',x:40,y:40,rot:1}));
 assert.equal(act(w,p,'build',{kind:'wall',x:50,y:60}),false);
 p.x=100;p.y=100;assert.equal(act(w,p,'build',{kind:'wall',x:40,y:45}),false);
});

test('portón abre paso y no cierra sobre personas ni infectados; rival no lo acciona',()=>{
 const {w,p}=fixture();act(w,p,'build',{kind:'gate',x:43,y:58});const b=w.walls[0];p.x=43;p.y=61;
 assert.equal(solid(w,43,58),true);assert.ok(act(w,p,'use',{id:b.id},1000));assert.equal(solid(w,43,58),false);
 p.y=58;assert.equal(act(w,p,'use',{id:b.id},1400),false);p.y=61;
 w.zombies=[{id:'z',x:43,y:58,hp:68}];assert.equal(act(w,p,'use',{id:b.id},1500),false);w.zombies=[];
 assert.ok(act(w,p,'use',{id:b.id},1600));assert.equal(solid(w,43,58),true);
 const rival=join(w,'r','R','city');rival.x=43;rival.y=61;assert.equal(act(w,rival,'use',{id:b.id},2000),false);
});

test('taller, enfermería y almacén producen beneficios con recursos y propiedad validados',()=>{
 for(const kind of ['workshop','infirmary','storage']){
  const {w,p}=fixture();act(w,p,'build',{kind,x:43,y:58});p.x=43;p.y=61;const b=w.walls[0],wood=p.wood;
  if(kind==='workshop'){const ammo=p.reserve;assert.ok(act(w,p,'use',{id:b.id}));assert.equal(p.reserve,ammo+30);assert.equal(p.wood,wood-15);}
  if(kind==='infirmary'){assert.equal(act(w,p,'use',{id:b.id}),false);p.hp=40;assert.ok(act(w,p,'use',{id:b.id}));assert.equal(p.hp,75);assert.equal(p.wood,wood-10);}
  if(kind==='storage'){assert.ok(act(w,p,'deposit'));assert.equal(b.stock,20);assert.ok(act(w,p,'use',{id:b.id}));assert.equal(p.wood,wood);assert.equal(b.stock,0);assert.equal(act(w,p,'use',{id:b.id}),false);}
 }
});

test('agua y alimentos tienen producción limitada y no se gastan al estar lleno',()=>{
 for(const kind of ['well','garden']){
  const {w,p}=fixture();act(w,p,'build',{kind,x:43,y:58},1000);p.x=43;p.y=61;const b=w.walls[0];
  assert.equal(act(w,p,'use',{id:b.id},1000),false);structuresTick(w,.1,361000);assert.equal(b.stock,5);
  assert.equal(act(w,p,'use',{id:b.id},361001),false);assert.equal(b.stock,5);
  p.hunger=20;p.thirst=20;assert.ok(act(w,p,'use',{id:b.id},361002));assert.equal(b.stock,4);
  assert.equal(kind==='well'?p.thirst:p.hunger,kind==='well'?60:55);
 }
});

test('pinchos transitables dañan una vez por segundo y tienen desgaste',()=>{
 const {w,p}=fixture();act(w,p,'build',{kind:'spikes',x:43,y:58});const b=w.walls[0];
 assert.equal(solid(w,43,58),false);w.zombies=[{id:'z',x:43,y:58,hp:68}];
 structuresTick(w,.1,1000);assert.equal(w.zombies[0].hp,50);assert.equal(b.hp,85);
 structuresTick(w,.1,1100);assert.equal(w.zombies[0].hp,50);
 structuresTick(w,.1,2000);assert.equal(w.zombies[0].hp,32);
 const drops=w.drops.length;structuresTick(w,.1,3000);structuresTick(w,.1,4000);structuresTick(w,.1,5000);assert.equal(w.drops.length,drops+1);
});

test('necesidades solo bajan para vivos conectados y causan daño al agotarse',()=>{
 const {w,p}=fixture();tick(w,new Map(),new Set(),1,1000);assert.equal(p.thirst,100);
 tick(w,new Map(),new Set(['a']),1,1100);assert.equal(p.thirst,99.93);
 p.hunger=0;p.hp=1;tick(w,new Map(),new Set(['a']),1,1200);assert.equal(p.alive,false);
});

test('v4 migra con respaldo exacto; normaliza recarga y conserva estructuras v5 al releer',()=>{
 const directory=mkdtempSync(pathJoin(tmpdir(),'cerco-rts-'));
 try{const {w,p}=fixture();w.version=4;p.reload=-0.01;delete p.hunger;delete p.thirst;
  const raw=JSON.stringify({version:4,worlds:[w],accounts:{key:{id:'a',worldId:w.id}}});writeFileSync(directory+'/world.json',raw);
  const store=openStore(directory,1000),m=store.data.worlds[0],q=m.players.a;
  assert.equal(store.data.version,6);assert.equal(q.reload,0);assert.equal(q.thirst,100);assert.equal(readFileSync(directory+'/world.json.v4.bak','utf8'),raw);
  act(m,q,'build',{kind:'storage',x:43,y:58});m.walls[0].stock=73;store.save();
  const restored=openStore(directory,2000).data;assert.equal(restored.worlds[0].walls[0].stock,73);assert.equal(restored.accounts.key.id,'a');
 }finally{rmSync(directory,{recursive:true,force:true});}
});
