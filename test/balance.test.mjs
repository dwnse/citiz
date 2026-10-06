import {test} from 'node:test';
import assert from 'node:assert/strict';
import {BALANCE,supplyLoot,nextWaveLevel} from '../src/balance.mjs';
import {createWorld,join,tick} from '../src/world.mjs';
import {supplyForecast} from '../src/population.mjs';
import {structuresTick} from '../src/structures.mjs';
import {damageInfected} from '../src/loot.mjs';

test('botín común devuelve munición parcial; jefe y muerte repetida no duplican recompensa',()=>{
 const loot=Array.from({length:16},(_,i)=>supplyLoot(String.fromCharCode(64+i)));
 assert.equal(loot.reduce((n,r)=>n+r.ammo,0)/16,1.5);
 assert.equal(loot.reduce((n,r)=>n+r.food,0),2);assert.equal(loot.reduce((n,r)=>n+r.water,0),2);assert.equal(loot.reduce((n,r)=>n+r.medical,0),1);
 const w=createWorld(1000),z={id:'boss',x:30,y:30,hp:50,boss:true};w.drops=[];
 assert.equal(damageInfected(w,z,50,2000,'forest'),true);assert.equal(damageInfected(w,z,50,2000,'forest'),false);assert.equal(w.drops.length,1);assert.equal(w.drops[0].ammo,12);
});
test('oleadas dan preparación inicial y la progresión no vuelve al nivel uno',()=>{
 assert.deepEqual(Array.from({length:10},(_,i)=>nextWaveLevel(i)),[1,1,1,2,2,2,3,3,3,3]);
 const w=createWorld(1000),p=join(w,'a','A');assert.equal(w.nextWave,1000+BALANCE.firstWaveMs);
 tick(w,new Map(),new Set(['a']),.1,2000);assert.equal(w.wave,0);
 w.nextWave=3000;tick(w,new Map(),new Set(['a']),.1,3000);assert.equal(w.wave,1);assert.equal(w.nextWave,63000);
 w.adventure.elapsed=400;w.zombies=[];w.nextWave=4000;tick(w,new Map(),new Set(['a']),.1,4000);assert.equal(w.nextWave,49000);
});
test('balance alimentario contempla riego, mejora, lluvia y demanda sin inventar reservas',()=>{
 const w=createWorld(1000),c=w.communities[0];c.settlers=2;
 const garden={id:'g',kind:'garden',communityId:c.id,hp:160,x:40,y:60,stock:0},well={id:'w',kind:'well',communityId:c.id,hp:300,x:44,y:60,stock:0};w.walls=[garden,well];
 let f=supplyForecast(w,c);assert.equal(f.foodPerMinute,1.25);assert.equal(f.waterPerMinute,2);assert.equal(f.foodBalance,.25);
 c.settlers=6;f=supplyForecast(w,c);assert.ok(f.foodBalance<0&&f.waterBalance<0);
 garden.level=2;assert.equal(supplyForecast(w,c).foodPerMinute,1.875);
 w.walls=[{...well,kind:'raincollector'}];w.adventure={weather:'rain'};assert.equal(supplyForecast(w,c).waterPerMinute,60000/22500);assert.equal(w.walls[0].stock,0);
});
test('mejorar puesto acelera extracción e investigar aumenta carga sin duplicar el recurso',()=>{
 const run=(level,tech)=>{const w=createWorld(1000),p=join(w,'a','A'),c=w.communities[0];w.obstacles=[];w.resources=[{id:'tree',kind:'tree',x:70,y:80,hits:5}];c.settlers=1;c.tech=tech;
 w.walls=[{id:'home',kind:'shelter',communityId:c.id,x:60,y:80,hp:300},{id:'mill',kind:'sawmill',communityId:c.id,x:66,y:80,hp:220,stock:0,level}];
 w.workers=[{id:'resident-forest-0',communityId:c.id,x:70,y:81.7,name:'Inés',work:0,jobId:'mill'}];
 for(let i=0;i<121;i++)structuresTick(w,.1,2000+i*100,new Set([p.id]));return w;};
 const base=run(0,0),improved=run(2,3);assert.equal(base.resources[0].hits,5);assert.equal(improved.resources[0].hits,4);assert.equal(improved.workers[0].cargo.amount,9);assert.equal(improved.walls[1].stock,0);
});
