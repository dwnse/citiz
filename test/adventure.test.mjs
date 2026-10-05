import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createWorld,join,action,tick,snapshot} from '../src/world.mjs';
import {inventory,addMaterials} from '../src/inventory.mjs';
import {initializeAdventure} from '../src/adventure.mjs';
import {structuresTick} from '../src/structures.mjs';
import {interactStory,SPELLS} from '../src/story.mjs';
import {collectLoot} from '../src/loot.mjs';
import {openStore} from '../src/storage.mjs';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join as pathJoin} from 'node:path';
function setup(){const w=createWorld(1000),p=join(w,'a','A');w.obstacles=[];w.resources=[];w.resourceLayout=2;w.nearbyResourcesVersion=1;w.nextWave=1e9;return {w,p,c:w.communities[0],online:new Set([p.id])};}
const act=(w,p,type,extra={},now=2000,online=new Set([p.id]))=>action(w,p,{type,seq:p.seq+1,...extra},now,online);
const building=(w,p,kind,extra={})=>{const b={id:kind,kind,communityId:p.communityId,x:p.x+2,y:p.y,hp:300,maxHp:300,stock:0,producedAt:1000,...extra};w.walls.push(b);return b;};

test('recetas y filas conservan tipos; rechazo no descuenta piezas parciales',()=>{
 const {w,p}=setup();p.x=40;p.y=50;p.wood=0;inventory(p);addMaterials(p,'timber',42);addMaterials(p,'stone',12);
 const before=structuredClone(p.materials);
 assert.equal(act(w,p,'build_row',{kind:'wall',x:36,y:52,endX:42.4,endY:52}),false);
 assert.equal(w.walls.length,0);assert.deepEqual(p.materials,before);assert.equal(p.wood,54);
 addMaterials(p,'reclaimed',6);assert.ok(act(w,p,'build_row',{kind:'wall',x:36,y:52,endX:42.4,endY:52}));
 assert.equal(w.walls.length,3);assert.equal(p.wood,0);assert.equal(Object.values(p.materials).reduce((a,b)=>a+b,0),0);
});
test('almacenar, desmontar y recoger no convierte recursos en recuperados',()=>{
 const {w,p}=setup();p.wood=0;inventory(p);addMaterials(p,'stone',20);const b=building(w,p,'storage');
 assert.ok(act(w,p,'deposit_materials',{id:b.id}));assert.equal(b.materials.stone,20);assert.equal(p.wood,0);
 assert.ok(act(w,p,'dismantle',{id:b.id}));const d=w.drops.find(d=>d.materials);collectLoot(w,p,d);
 assert.equal(p.materials.stone,20);assert.equal(p.materials.reclaimed,17);assert.equal(p.wood,37);
});
test('expediciones tienen espera compartida; hospital requiere alojamiento; informe se entrega una vez',()=>{
 const {w,p,c}=setup(),site=initializeAdventure(w).sites[0];p.x=site.x;p.y=site.y;
 assert.ok(act(w,p,'expedition'));assert.equal(p.medical,2);assert.equal(act(w,p,'expedition'),false);
 p.x=c.x-4;p.y=c.y;assert.equal(act(w,p,'deliver'),false);assert.ok(p.cargo);
 building(w,p,'shelter');assert.ok(act(w,p,'deliver'));assert.equal(c.research,1);assert.equal(c.settlers,1);
 assert.equal(act(w,p,'deliver'),false);assert.equal(c.research,1);
 const other=join(w,'b','B');other.x=site.x;other.y=site.y;assert.equal(act(w,other,'expedition'),false);
});
test('pausa individual congela temporizadores y rechaza acciones; otro jugador la cancela',()=>{
 const {w,p,online}=setup();p.ammo=0;p.reload=1;w.nextWave=7000;
 const b=building(w,p,'generator',{fuelUntil:10000});w.resources=[{id:'r',kind:'rock',x:20,y:20,hits:0,maxHits:5,readyAt:10000}];
 assert.ok(act(w,p,'pause',{},2000,online));tick(w,new Map(),online,1,5000);
 assert.equal(p.reload,1);assert.equal(w.nextWave,10000);assert.equal(b.fuelUntil,13000);assert.equal(w.resources[0].readyAt,13000);
 assert.equal(act(w,p,'craft',{},5000,online),false);assert.equal(p.wood,100);
 assert.ok(act(w,p,'pause',{},6000,online));assert.equal(b.fuelUntil,14000);
 assert.ok(act(w,p,'pause',{},6000,online));const q=join(w,'b','B');online.add(q.id);tick(w,new Map(),online,.1,7000);
 assert.equal(w.pausedBy,null);assert.equal(act(w,p,'pause',{},7000,online),false);
});
test('correr gasta resistencia solo en movimiento; esquiva tiene coste y enfriamiento',()=>{
 const {w,p,online}=setup();p.x=80;p.y=80;
 assert.ok(act(w,p,'sprint',{enabled:true}));tick(w,new Map(),online,1,2000);assert.equal(p.stamina,100);
 tick(w,new Map([[p.id,{x:1,y:0,at:2100}]]),online,1,2100);assert.equal(p.stamina,82);assert.ok(p.x>90);
 assert.ok(act(w,p,'dodge',{},2100));assert.equal(p.stamina,57);assert.equal(act(w,p,'dodge',{},2200),false);assert.equal(p.stamina,57);
});
test('armas cobran solo al fabricar, protegen recarga y conservan todas las balas al cambiar',()=>{
 const {w,p,online}=setup();building(w,p,'workshop');addMaterials(p,'components',6);p.wood+=200;inventory(p);
 p.reload=1;const funds=p.wood;assert.equal(act(w,p,'weapon',{weapon:'shotgun'}),false);assert.equal(p.wood,funds);
 p.reload=0;assert.ok(act(w,p,'weapon',{weapon:'shotgun'}));assert.equal(p.wood,funds-62);assert.equal(p.reserve,72);assert.equal(p.ammo,0);
 assert.ok(act(w,p,'reload'));tick(w,new Map(),online,2.3,4300);assert.equal(p.ammo,6);assert.equal(p.reserve,66);
 assert.ok(act(w,p,'weapon',{weapon:'pistol'},4400));assert.equal(p.reserve,72);const paid=p.wood;
 assert.ok(act(w,p,'weapon',{weapon:'shotgun'},4500));assert.equal(p.wood,paid);assert.equal(p.reserve+p.ammo,72);
 assert.equal(act(w,p,'weapon',{weapon:'__proto__'}),false);
});
test('trabajadores requieren plazas y recursos; producción se recoge sin duplicar y cesa al destruir refugio',()=>{
 const {w,p,c,online}=setup();c.settlers=1;const house=building(w,p,'shelter',{x:p.x-4}),mill=building(w,p,'sawmill',{id:'mill'});w.resources=[{id:'tree',kind:'tree',x:mill.x+5,y:mill.y,hits:5,maxHits:5}];
 for(let i=0;i<400&&!mill.stock;i++)structuresTick(w,.1,2000+i*100,online);assert.equal(mill.stock,6);assert.equal(w.resources[0].hits,4);
 assert.ok(act(w,p,'use',{id:mill.id}));assert.equal(p.materials.timber,6);assert.equal(act(w,p,'use',{id:mill.id}),false);
 house.hp=0;structuresTick(w,1,41000,online);assert.equal(mill.stock,0);assert.equal(mill.working,false);
});
test('seis claves despiertan un solo Paciente 0; muestra y tres informes permiten un final persistente',()=>{
 const {w,p,c}=setup();p.intro=true;p.prologue=2;w.story.communities[c.id].fragments=SPELLS.map(s=>s.id);p.x=w.story.seal.x-4;p.y=w.story.seal.y;
 interactStory(w,p,2000);interactStory(w,p,2001);assert.equal(w.zombies.filter(z=>z.finalBoss).length,1);
 const boss=w.zombies.find(z=>z.finalBoss);boss.hp=34;assert.ok(act(w,p,'shoot',{angle:0}));assert.equal(w.story.patient.defeated,true);
 const sample=w.drops.find(d=>d.sample);assert.ok(sample);p.x=sample.x;p.y=sample.y;assert.ok(act(w,p,'interact'));assert.equal(p.sample,true);
 const lab=building(w,p,'laboratory');assert.equal(act(w,p,'use',{id:lab.id}),false);assert.equal(p.sample,true);
 c.research=3;assert.ok(act(w,p,'use',{id:lab.id}));assert.equal(w.phase,'victory');assert.equal(c.research,0);assert.equal(p.reward.title,'Custodio del Sello');assert.equal(act(w,p,'use',{id:lab.id}),false);
 const directory=mkdtempSync(pathJoin(tmpdir(),'cerco-progression-'));
 try{const store=openStore(directory,1000);store.data.worlds=[w];store.save();const saved=openStore(directory,3000).data.worlds[0];assert.equal(saved.phase,'victory');assert.equal(saved.players.a.reward.worldId,w.id);assert.deepEqual(saved.players.a.materials,p.materials);}finally{rmSync(directory,{recursive:true,force:true});}
});
test('investigación consume informes y componentes una vez, limita niveles y mejora extracción',()=>{
 const {w,p,c}=setup();const lab=building(w,p,'laboratory');c.research=6;addMaterials(p,'components',6);
 for(let i=0;i<3;i++)assert.ok(act(w,p,'use',{id:lab.id}));assert.equal(c.tech,3);assert.equal(c.research,0);assert.equal(p.materials.components,0);assert.equal(act(w,p,'use',{id:lab.id}),false);
 w.walls=[];w.resources=[{id:'tree',kind:'tree',x:p.x+2,y:p.y,hits:5,maxHits:5}];p.equipped='tool';assert.ok(act(w,p,'harvest',{id:'tree'}));assert.equal(p.materials.timber,9);
 assert.equal(snapshot(w,p.id,new Set([p.id]),2000).adventure.guide.step,1);
});
