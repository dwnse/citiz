import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createWorld,join,action,tick} from '../src/world.mjs';
import {bossFields,bossTick,pruneFallen} from '../src/enemies.mjs';
import {damageInfected} from '../src/loot.mjs';
import {structuresTick} from '../src/structures.mjs';
import {populationView} from '../src/population.mjs';
const setup=()=>{const w=createWorld(1000),p=join(w,'a','A');w.obstacles=[];w.resources=[];w.resourceLayout=2;w.nearbyResourcesVersion=1;w.nextWave=1e9;p.x=80;p.y=80;return {w,p,c:w.communities[0],online:new Set([p.id])};};
const zombie=(id,x,y,extra={})=>({id,x,y,communityId:'forest',hp:100,maxHp:100,attack:0,level:1,boss:false,...extra});
const boss=(w,type)=>{const z=zombie('boss',85,80,bossFields(type));w.zombies.push(z);return z;};
const act=(w,p,type,extra={},now=2000)=>action(w,p,{type,seq:p.seq+1,...extra},now,new Set([p.id]));
const building=(w,kind,id,x,extra={})=>{const b={id,kind,communityId:'forest',x,y:80,hp:300,maxHp:300,stock:0,producedAt:1000,...extra};w.walls.push(b);return b;};

test('Cantor avisa antes de curar, respeta máximo y excluye infectados controlados',()=>{
 const {w,p}=setup(),z=boss(w,'healer'),ally=zombie('ally',88,80,{hp:80}),charmed=zombie('charmed',89,80,{hp:10,charmUntil:9000});w.zombies.push(ally,charmed);z.ability=0;
 bossTick(w,z,[p],.1,2000,()=>{});assert.equal(ally.hp,80);assert.equal(z.warning,2.5);
 bossTick(w,z,[p],2.4,4400,()=>{});assert.equal(ally.hp,80);
 bossTick(w,z,[p],.2,4600,()=>{});assert.equal(ally.hp,100);assert.equal(charmed.hp,10);assert.equal(z.warning,0);
});
test('tres disparos interrumpen una habilidad y evitan su efecto',()=>{
 const {w,p,online}=setup(),z=boss(w,'healer'),ally=zombie('ally',89,80,{hp:10});w.zombies.push(ally);z.ability=0;bossTick(w,z,[p],.1,2000,()=>{});
 for(let i=0;i<3;i++){assert.ok(act(w,p,'shoot',{angle:0},2100+i*300));tick(w,new Map(),online,.3,2400+i*300);}
 assert.equal(z.warning,0);assert.ok(z.interruptedUntil>2700);assert.equal(ally.hp,10);assert.equal(p.ammo,9);
});
test('Sepulturero levanta como máximo dos caídos con media vida y nunca duplica botín',()=>{
 const {w,p}=setup(),z=boss(w,'reviver');
 for(let i=0;i<3;i++){const victim=zombie('dead'+i,87+i*2,82);w.zombies.push(victim);damageInfected(w,victim,100,2000,'forest');}
 const loot=w.drops.length;z.warning=.1;bossTick(w,z,[p],.2,3000,()=>{});
 const raised=w.zombies.filter(q=>q.reanimated);assert.equal(raised.length,2);assert.ok(raised.every(q=>q.hp===50));
 for(const q of raised)damageInfected(w,q,100,4000,'forest');assert.equal(w.drops.length,loot);assert.equal(w.fallen.length,3);
 z.warning=.1;bossTick(w,z,[p],.2,5000,()=>{});assert.equal(w.zombies.filter(q=>q.reanimated&&q.hp>0).length,1);assert.equal(w.fallen.filter(q=>q.raised).length,3);
 pruneFallen(w,65001);assert.equal(w.fallen.length,0);
});
test('resurrección respeta cupo y obstáculos; Heraldo potencia y el efecto caduca',()=>{
 const {w,p,online}=setup(),z=boss(w,'reviver');w.fallen=[{id:'dead',x:87,y:80,maxHp:100,level:1,diedAt:2000}];w.obstacles=[{x:87,y:80,sx:1,sy:1}];z.warning=.1;bossTick(w,z,[p],.2,3000,()=>{});assert.equal(w.zombies.length,1);
 w.obstacles=[];for(let i=0;i<95;i++)w.zombies.push(zombie('cap'+i,120+i%5,120));z.warning=.1;bossTick(w,z,[p],.2,4000,()=>{});assert.equal(w.zombies.length,96);
 w.zombies=[];const rally=boss(w,'rally'),runner=zombie('runner',88,80);w.zombies.push(runner);rally.warning=.1;bossTick(w,rally,[p],.2,5000,()=>{});assert.equal(runner.rallyUntil,13000);
 const first=runner.x;tick(w,new Map(),online,.1,5100);const boosted=first-runner.x;const second=runner.x;tick(w,new Map(),online,.1,14000);assert.ok(boosted>second-runner.x);
});
test('puestos priorizados, pausados o llenos liberan trabajadores para otra producción',()=>{
 const {w,p,c,online}=setup();c.x=c.vault.x=80;c.y=c.vault.y=80;c.settlers=1;building(w,'shelter','home',82);const mill=building(w,'sawmill','mill',82),quarry=building(w,'quarry','quarry',78);
 w.resources=[{id:'tree',kind:'tree',x:84,y:84,hits:5,maxHits:5},{id:'rock',kind:'rock',x:75,y:84,hits:5,maxHits:5}];
 structuresTick(w,.1,2000,online);assert.equal(mill.working,true);assert.equal(quarry.working,false);
 assert.ok(act(w,p,'staff',{id:quarry.id}));structuresTick(w,.1,2001,online);assert.equal(quarry.working,true);assert.equal(mill.working,false);
 quarry.stock=60;structuresTick(w,.1,2002,online);assert.equal(mill.working,true);assert.match(quarry.workerReason,/llena/);
 assert.ok(act(w,p,'unstaff',{id:mill.id}));structuresTick(w,.1,2003,online);assert.equal(mill.working,false);assert.match(mill.workerReason,/manualmente/);
});
test('raciones se consumen atómicamente; donar reactiva puestos y no se consumen desconectados',()=>{
 const {w,p,c,online}=setup();c.settlers=2;c.workforce={food:1,water:0,fedUntil:1500};const house=building(w,'shelter','home',82),mill=building(w,'sawmill','mill',78);w.resources=[{id:'tree',kind:'tree',x:75,y:82,hits:5,maxHits:5}];
 structuresTick(w,.1,2000,online);assert.equal(c.workforce.food,1);assert.equal(mill.working,false);assert.match(mill.workerReason,/comida o agua/);
 p.food=1;p.water=0;assert.equal(act(w,p,'supply_workers',{id:house.id}),false);assert.equal(p.food,1);
 p.water=1;assert.ok(act(w,p,'supply_workers',{id:house.id}));structuresTick(w,.1,2001,online);assert.equal(mill.working,true);assert.equal(c.workforce.food,1);assert.equal(c.workforce.water,0);
 c.workforce.water=1;structuresTick(w,.1,100000,new Set());assert.equal(c.workforce.food,1);assert.equal(c.workforce.water,1);assert.equal(mill.working,false);
 const view=populationView(w,c,100000);assert.equal(view.residents,2);assert.equal(view.capacity,2);assert.equal(view.working,0);
});

test('dos puestos no duplican el último golpe de un mismo recurso',()=>{
 const {w,c,online}=setup();c.settlers=2;building(w,'shelter','home',82,{y:74});const first=building(w,'sawmill','first',82),second=building(w,'sawmill','second',78);
 w.resources=[{id:'tree',kind:'tree',x:80,y:84,hits:1,maxHits:5}];for(let i=0;i<450;i++)structuresTick(w,.1,2000+i*100,online);
 assert.equal(first.stock+second.stock,6);assert.equal(w.resources[0].hits,0);assert.equal(second.working,false);
});

test('la descarga respeta su radio y solo golpea una vez por preparación',()=>{
 const {w,p}=setup(),z=boss(w,'bulwark'),outside={...p,id:'far',x:100};z.warning=.1;
 const hurt=(_w,agent,damage)=>agent.hp-=damage;
 bossTick(w,z,[p,outside],.2,2000,hurt);assert.equal(p.hp,65);assert.equal(outside.hp,100);
 bossTick(w,z,[p,outside],.2,2200,hurt);assert.equal(p.hp,65);
});
test('el ruido atrae a un infectado aunque otro agente silencioso esté más cerca',()=>{
 const {w,p}=setup(),quiet=join(w,'quiet','Quiet');p.x=80;p.y=108;p.noiseUntil=8000;quiet.x=100;quiet.y=80;
 const z=zombie('listener',80,80);w.zombies=[z];const online=new Set([p.id,quiet.id]);
 tick(w,new Map(),online,.1,2000);assert.ok(z.y>80);assert.equal(z.x,80);
 tick(w,new Map(),online,.1,9000);assert.ok(z.x<80);
});
