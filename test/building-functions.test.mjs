import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createWorld,join,action,snapshot} from '../src/world.mjs';
import {structuresTick,structureStatus} from '../src/structures.mjs';
function fixture(kind){const w=createWorld(0),p=join(w,'p','P');p.wood=1000;action(w,p,{type:'build',seq:1,kind,x:43,y:58},0);p.x=43;p.y=61;return {w,p,b:w.walls[0]};}
const act=(w,p,type,b,now=100)=>action(w,p,{type,id:b.id,seq:p.seq+1},now);
test('taller refuerza blindaje con coste, máximo y permisos',()=>{
 const {w,p,b}=fixture('workshop');p.armor=85;const wood=p.wood;
 assert.ok(act(w,p,'armor',b));assert.equal(p.armor,100);assert.equal(p.wood,wood-25);
 assert.equal(act(w,p,'armor',b),false);assert.equal(p.wood,wood-25);
 p.armor=0;p.x=100;assert.equal(act(w,p,'armor',b),false);p.x=43;
 const q=join(w,'q','Q','city');q.x=43;q.y=61;assert.equal(act(w,q,'armor',b),false);
});
test('portón automático espera cinco segundos y no aplasta ocupantes',()=>{
 const {w,p,b}=fixture('gate');act(w,p,'auto_close',b,100);act(w,p,'use',b,100);
 structuresTick(w,.1,5099);assert.ok(b.open);p.y=58;structuresTick(w,.1,5100);assert.ok(b.open);
 p.y=61;structuresTick(w,.1,5200);assert.equal(b.open,false);
 act(w,p,'auto_close',b,5300);act(w,p,'use',b,5400);structuresTick(w,.1,20000);assert.ok(b.open);
});
test('almacén limita transferencias y devuelve contenido una sola vez al desmontar',()=>{
 const {w,p,b}=fixture('storage');b.stock=195;p.reserve=40;
 const wood=p.wood;act(w,p,'deposit_materials',b);assert.equal(b.stock,200);assert.equal(p.wood,wood-5);
 assert.equal(act(w,p,'deposit_materials',b),false);act(w,p,'deposit_ammo',b);assert.equal(p.reserve,10);assert.equal(b.ammoStock,30);
 act(w,p,'withdraw_ammo',b);assert.equal(p.reserve,40);assert.equal(b.ammoStock,0);
 act(w,p,'deposit_ammo',b);const count=w.drops.length;act(w,p,'dismantle',b);assert.equal(w.drops.length,count+1);assert.equal(w.drops.at(-1).ammo,30);assert.equal(w.drops.at(-1).wood,200);
 assert.equal(act(w,p,'dismantle',b),false);assert.equal(w.drops.length,count+1);
});
test('pozo aliado acelera huerto próximo; destrucción detiene el beneficio y pinchos protegen controlados',()=>{
 const {w,p,b}=fixture('garden');w.walls.push({id:'well',kind:'well',communityId:p.communityId,x:46.2,y:58,hp:300,producedAt:0});
 assert.equal(structureStatus(w,b,0).interval,48);structuresTick(w,.1,48000);assert.equal(b.stock,1);
 w.walls[1].hp=0;assert.equal(structureStatus(w,b,48000).interval,60);
 b.kind='spikes';b.level=2;w.zombies=[{id:'z',x:43,y:58,hp:100},{id:'friend',x:43,y:58,hp:100,charmUntil:90000}];
 structuresTick(w,.1,49000);assert.equal(w.zombies[0].hp,70);assert.equal(w.zombies[1].hp,100);
 assert.ok(snapshot(w,p.id,new Set(),49000).walls[0].operation.description.includes('30 daño'));
});
