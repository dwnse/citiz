import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createWorld,join,action,snapshot} from '../src/world.mjs';
import {workersTick} from '../src/workers.mjs';
import {solid} from '../src/navigation.mjs';
import {prepareWorkforce} from '../src/population.mjs';

function setup(){
 const w=createWorld(1000),p=join(w,'a','A'),c=w.communities[0];
 w.obstacles=[];w.resources=[];w.resourceLayout=2;w.nearbyResourcesVersion=1;w.walls=[];w.drops=[];c.settlers=2;
 p.x=c.x;p.y=c.y+5;
 w.workers=[0,1].map(i=>({id:'resident-forest-'+i,communityId:c.id,name:'Residente '+i,x:c.x-10,y:c.y+10+i*2,work:0,angle:0}));
 const order=(id,type,extra={})=>action(w,p,{type:'worker_order',id,order:type,seq:p.seq+1,...extra},2000,new Set(['a']));
 const advance=(seconds,online=new Set(['a']))=>{for(let i=0;i<seconds*30;i++){workersTick(w,new Map(),online,1/30,2000+i*1000/30);for(const q of w.workers)assert.equal(solid(w,q.x,q.y),false);}};
 return {w,p,c,order,advance,npc:w.workers[0]};
}
test('órdenes validan propiedad, base, destino, pausa y secuencia',()=>{
 const {w,p,c,order,npc}=setup();
 assert.equal(order(npc.id,'move',{x:c.x-5,y:c.y+12}),true);
 const prior=structuredClone(npc.order);
 assert.equal(order(npc.id,'move',{x:NaN,y:0}),false);assert.deepEqual(npc.order,prior);
 assert.equal(order(npc.id,'move',{x:c.x,y:c.y}),false);
 assert.equal(order(npc.id,'move',{x:c.x+80,y:c.y}),false);
 npc.communityId='city';assert.equal(order(npc.id,'hold'),false);npc.communityId='forest';
 p.x+=60;assert.equal(order(npc.id,'hold'),false);p.x=c.x;
 w.pausedBy=p.id;assert.equal(order(npc.id,'hold'),false);delete w.pausedBy;
 assert.equal(action(w,p,{type:'worker_order',id:npc.id,order:'hold',seq:p.seq},2000),false);
});
test('mover llega y espera; órdenes conservan carga, persisten y se congelan offline',()=>{
 const {w,c,order,npc,advance}=setup();
 w.walls=[{id:'mill',kind:'sawmill',communityId:'forest',x:c.x-15,y:c.y+15,hp:200,stock:0}];
 npc.jobId='mill';npc.cargo={kind:'timber',amount:6};
 assert.equal(order(npc.id,'move',{x:c.x-5,y:c.y+12}),true);
 const old={x:npc.x,y:npc.y};advance(1,new Set());assert.equal(npc.x,old.x);assert.equal(npc.y,old.y);
 advance(5);assert.equal(npc.order.type,'hold');assert.equal(npc.cargo.amount,6);assert.equal(w.walls[0].stock,0);
 assert.deepEqual(JSON.parse(JSON.stringify(w)).workers[0].order,{type:'hold'});
 assert.equal(order(npc.id,'auto'),true);advance(6);assert.equal(npc.cargo,null);assert.equal(w.walls[0].stock,6);
});
test('residentes se separan y no cruzan geometría al converger',()=>{
 const {w,c,order,advance}=setup();
 for(const npc of w.workers)order(npc.id,'move',{x:c.x-4,y:c.y+10});
 advance(7);
 assert.ok(Math.hypot(w.workers[0].x-w.workers[1].x,w.workers[0].y-w.workers[1].y)>=.8);
});
test('amenaza interrumpe órdenes y la vista de población solo expone residentes propios',()=>{
 const {w,p,npc,order,advance}=setup();order(npc.id,'hold');
 w.zombies=[{id:'danger',x:npc.x+1,y:npc.y,hp:50}];advance(.2);assert.match(npc.status,/refugio|Refugiado/);assert.equal(npc.order.type,'hold');
 w.workers.push({id:'foreign',communityId:'city',name:'Rival',x:p.x,y:p.y});
 assert.equal(snapshot(w,p.id,new Set(['a']),2000).population.people.some(q=>q.id==='foreign'),false);
});
test('orden manual libera capacidad de producción y abrir el paso permite continuar',()=>{
 const {w,c,npc,order,advance}=setup();
 w.walls=[{id:'home',kind:'shelter',communityId:'forest',x:60,y:60,hp:300},...['one','two'].map((id,i)=>({id,kind:'sawmill',communityId:'forest',x:62+i*5,y:65,hp:200,stock:0}))];
 w.resources=[{id:'tree',kind:'tree',x:64,y:69,hits:5}];
 assert.equal(prepareWorkforce(w,new Set(['a']),2000).size,2);
 order(npc.id,'hold');assert.equal(prepareWorkforce(w,new Set(['a']),2000).size,1);
 order(npc.id,'auto');assert.equal(prepareWorkforce(w,new Set(['a']),2000).size,2);
 w.walls=[];w.resources=[];w.obstacles=[{x:43,y:60,sx:.4,sy:60}];
 order(npc.id,'move',{x:46,y:60});advance(3);assert.ok(npc.x<43);assert.match(npc.status,/bloqueado/);
 w.obstacles=[];advance(5);assert.equal(npc.order.type,'hold');assert.ok(Math.hypot(npc.x-46,npc.y-60)<.7);
});
