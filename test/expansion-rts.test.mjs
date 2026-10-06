import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createWorld,join,action} from '../src/world.mjs';
import {structuresTick,placementReason,catalog} from '../src/structures.mjs';
import {initializeResources} from '../src/harvesting.mjs';
import {zombieLoot} from '../src/loot.mjs';
const act=(w,p,type,extra={},now=1000)=>action(w,p,{type,seq:p.seq+1,...extra},now);
function setup(){const w=createWorld(0),p=join(w,'p','P');p.wood=1000;p.x=43;p.y=61;return {w,p};}
test('torreta necesita energía y munición, respeta paredes, consume munición y produce botín único',()=>{
 const {w,p}=setup();assert.equal(catalog().length,18);
 act(w,p,'build',{kind:'turret',x:43,y:58});const turret=w.walls[0];
 act(w,p,'build',{kind:'generator',x:39.8,y:58});const generator=w.walls[1];
 w.zombies=[{id:'enemy',x:43,y:50,hp:24}];act(w,p,'use',{id:turret.id});structuresTick(w,.1,2000);assert.equal(w.zombies[0].hp,24);
 act(w,p,'use',{id:generator.id});w.walls.push({id:'block',kind:'wall',x:43,y:54,hp:180});structuresTick(w,.1,2000);assert.equal(w.zombies[0].hp,24);
 w.walls.pop();const n=w.drops.length;structuresTick(w,.1,2000);assert.equal(w.zombies[0].hp,0);assert.equal(turret.ammoStock,29);assert.equal(w.drops.length,n+1);assert.equal(w.drops.at(-1).wood,0);
 structuresTick(w,.1,3000);assert.equal(w.drops.length,n+1);
 w.zombies=[{id:'controlled',x:43,y:50,hp:100,charmUntil:200000}];structuresTick(w,.1,4000);assert.equal(w.zombies[0].hp,100);
 w.zombies[0].charmUntil=0;structuresTick(w,.1,100000);assert.equal(w.zombies[0].hp,100);
});
test('botín de zombis abastece mochila, consumo cobra una vez y cocina requiere ingredientes',()=>{
 const {w,p}=setup();w.drops=[];
 for(const id of 'abcdefghijklmnop')zombieLoot(w,{id,x:p.x,y:p.y});
 assert.ok(w.drops.every(d=>d.wood===0));for(let i=0;i<16;i++)assert.ok(act(w,p,'interact'));
 assert.equal(p.food,2);assert.equal(p.water,2);assert.equal(p.medical,1);
 p.hunger=10;act(w,p,'consume',{item:'food'});assert.equal(p.hunger,45);assert.equal(p.food,1);
 p.thirst=10;act(w,p,'consume',{item:'water'});assert.equal(p.thirst,50);assert.equal(p.water,1);
 act(w,p,'build',{kind:'kitchen',x:43,y:58});p.hp=70;assert.ok(act(w,p,'use',{id:w.walls[0].id}));assert.equal(p.hunger,100);assert.equal(p.hp,85);assert.equal(p.food,0);assert.equal(p.water,0);
 assert.equal(act(w,p,'use',{id:w.walls[0].id}),false);
});
test('distribución regional conserva recursos existentes y evita duplicados',()=>{
 const {w}=setup();w.resources=[{id:'old',x:20,y:60,kind:'tree',hits:2,maxHits:5,readyAt:0}];initializeResources(w);
 const count=w.resources.length;assert.ok(count>100);initializeResources(w);assert.equal(w.resources.length,count);assert.equal(w.resources[0].hits,2);
 const forest=w.resources.filter(r=>r.id.startsWith('forest-')),mountain=w.resources.filter(r=>r.id.startsWith('mountain-')),city=w.resources.filter(r=>r.id.startsWith('city-'));
 assert.ok(forest.filter(r=>r.kind==='tree').length>forest.filter(r=>r.kind==='rock').length);assert.ok(mountain.filter(r=>r.kind==='rock').length>mountain.filter(r=>r.kind==='tree').length);assert.ok(forest.length>city.length);
});
test('territorio explica distancia exterior, centro reservado y bóveda destruida',()=>{
 const {w,p}=setup();assert.match(placementReason(w,p,20,50,'wall',0,true),/AZUL|azul/);assert.match(placementReason(w,p,51,51,'wall',0,true),/rojo/);
 w.vault.hp=0;assert.match(placementReason(w,p,43,58,'wall',0,true),/destruida/);
});
test('reciclador no permite fabricar y reciclar para multiplicar materiales',()=>{
 const {w,p}=setup();act(w,p,'build',{kind:'recycler',x:43,y:58});const b=w.walls[0];act(w,p,'build',{kind:'generator',x:39.8,y:58});act(w,p,'use',{id:w.walls[1].id});
 p.reserve=10;const before=p.wood;assert.ok(act(w,p,'use',{id:b.id}));assert.equal(p.wood,before+3);assert.equal(p.reserve,0);assert.equal(act(w,p,'use',{id:b.id}),false);
});

