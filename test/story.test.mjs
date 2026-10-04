import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,rmSync,writeFileSync,readFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join as pathJoin} from 'node:path';
import {createWorld,join,action,tick,snapshot} from '../src/world.mjs';
import {SPELLS,cast,interactStory,storyTick,reservedStorySite} from '../src/story.mjs';
import {solid} from '../src/navigation.mjs';
import {openStore} from '../src/storage.mjs';
const setup=()=>{const w=createWorld(0),p=join(w,'a','A');w.nextWave=Infinity;return {w,p};};
const learn=p=>{p.intro=true;p.prologue=2;p.magic.known=SPELLS.map(s=>s.id);};
const zombie=(id,x,y,extra={})=>({id,x,y,hp:100,maxHp:100,level:1,attack:0,boss:false,communityId:'forest',...extra});

test('prólogo exige radio y bóveda; oculta señales hasta completarlo',()=>{
  const {w,p}=setup();assert.equal(action(w,p,{type:'intro',seq:1},1),false);
  assert.equal(snapshot(w,p.id,new Set(),1).story.mages.length,0);
  assert.ok(action(w,p,{type:'interact',seq:2},2));assert.equal(p.prologue,1);
  p.x=46;p.y=50;assert.ok(action(w,p,{type:'interact',seq:3},3));assert.equal(p.intro,true);
  assert.equal(snapshot(w,p.id,new Set(),3).story.mages.length,6);
});

test('seis encuentros comparten claves en la comunidad y enseñan a cada visitante',()=>{
  const {w,p}=setup(),ally=join(w,'ally','Ally'),enemy=join(w,'enemy','Enemy','city');
  for(const q of [p,ally,enemy]){q.intro=true;q.prologue=2;}
  Object.assign(p,w.story.seal);interactStory(w,p,1);assert.equal(w.story.communities.forest.opened,false);
  for(const m of w.story.mages){p.x=m.x;p.y=m.y;assert.ok(interactStory(w,p,2));assert.ok(interactStory(w,p,3));}
  assert.equal(p.magic.known.length,6);assert.equal(w.story.communities.forest.fragments.length,6);
  assert.equal(ally.magic.known.length,0);assert.equal(w.story.communities.city.fragments.length,0);
  const m=w.story.mages[0];ally.x=m.x;ally.y=m.y;interactStory(w,ally,4);assert.deepEqual(ally.magic.known,[m.power]);
  Object.assign(p,w.story.seal);assert.ok(interactStory(w,p,5));assert.equal(w.story.communities.forest.opened,true);
  assert.equal(w.phase,'active');assert.equal(w.story.communities.city.opened,false);
});

test('maná, recarga, secuencia y vida impiden lanzar poderes inválidos',()=>{
  const {w,p}=setup();p.hp=50;assert.equal(cast(w,p,'heal',1),false);learn(p);
  assert.ok(action(w,p,{type:'cast',power:'heal',seq:1},1));assert.equal(p.hp,75);assert.equal(p.magic.mana,80);
  assert.equal(action(w,p,{type:'cast',power:'heal',seq:1},13000),false);
  assert.equal(cast(w,p,'heal',2),false);p.magic.mana=19;assert.equal(cast(w,p,'heal',13000),false);
  p.magic.mana=100;p.alive=false;assert.equal(cast(w,p,'heal',13000),false);
  p.alive=true;p.hp=100;assert.equal(cast(w,p,'heal',13000),false);assert.equal(p.magic.mana,100);
});

test('ímpetu y fulgor alteran movimiento y daño solo durante su duración',()=>{
  const {w,p}=setup();learn(p);p.x=80;p.y=80;const online=new Set([p.id]);
  cast(w,p,'haste',1);tick(w,new Map([[p.id,{x:1,y:0,at:2}]]),online,.1,2);assert.ok(Math.abs(p.x-81.12)<1e-8);
  tick(w,new Map([[p.id,{x:1,y:0,at:7000}]]),online,.1,7000);assert.ok(Math.abs(p.x-81.82)<1e-8);
  w.zombies=[zombie('target',86,80)];cast(w,p,'fury',7001);action(w,p,{type:'shoot',angle:0,seq:1},7002);assert.equal(w.zombies[0].hp,52);
  p.cooldown=0;action(w,p,{type:'shoot',angle:0,seq:2},16000);assert.equal(w.zombies[0].hp,18);
});

test('temple y amparo absorben daño real y caducan sin restaurar escudos',()=>{
  const {w,p}=setup();learn(p);p.x=80;p.y=80;p.armor=0;const online=new Set([p.id]);
  cast(w,p,'resist',1);cast(w,p,'shield',1);w.zombies=[zombie('z',81,80)];
  tick(w,new Map(),online,.1,2);assert.equal(p.hp,100);assert.ok(Math.abs(p.magic.shieldHp-34.6)<1e-8);
  w.zombies[0].attack=0;tick(w,new Map(),online,.1,7000);assert.ok(Math.abs(p.hp-94.6)<1e-8);assert.equal(p.magic.shieldHp,0);
  w.zombies[0].attack=0;tick(w,new Map(),online,.1,9000);assert.ok(Math.abs(p.hp-85.6)<1e-8);
});

test('vínculo limita objetivos, excluye jefes, acredita bajas una vez y cesa al desconectar',()=>{
  const {w,p}=setup();learn(p);p.x=80;p.y=80;
  w.zombies=[zombie('a',81,80),zombie('b',82,80),zombie('c',83,80),zombie('d',84,80,{hp:22}),zombie('boss',85,80,{boss:true,ability:10,warning:0})];
  assert.ok(cast(w,p,'control',1));assert.equal(w.zombies.filter(z=>z.charmedBy).length,3);assert.equal(w.zombies[4].charmedBy,undefined);
  tick(w,new Map(),new Set([p.id]),.1,2);assert.equal(p.kills,1);const drops=w.drops.length;
  tick(w,new Map(),new Set([p.id]),.1,3);assert.equal(p.kills,1);assert.equal(w.drops.length,drops);
  tick(w,new Map(),new Set(),.1,4);assert.equal(w.zombies.some(z=>z.charmedBy),false);
});

test('vínculo no atraviesa obstáculos ni consume maná sin objetivos',()=>{
  const {w,p}=setup();learn(p);p.x=80;p.y=80;w.zombies=[zombie('z',86,80)];w.walls=[{id:'wall',x:83,y:80,rot:1,hp:180}];
  assert.equal(cast(w,p,'control',1),false);assert.equal(p.magic.mana,100);
});

test('recorridos de los seis magos permanecen libres y reservados',()=>{
  const {w,p}=setup();const before=w.story.mages.map(m=>m.y);
  for(let i=0;i<100;i++)storyTick(w,.1,230000+i*100,new Set([p.id]));
  for(const [i,m] of w.story.mages.entries()){assert.equal(solid(w,m.x,m.y),false);assert.ok(reservedStorySite(w,m.x,m.y));assert.notEqual(m.y,before[i]);}
});

test('migración v3 conserva copia exacta; v4 restaura claves, poderes y vencimientos',()=>{
  const dir=mkdtempSync(pathJoin(tmpdir(),'cerco-story-'));
  try{const {w,p}=setup();p.intro=true;delete w.story;delete w.effects;delete p.magic;w.version=3;
    const raw=JSON.stringify({version:3,worlds:[w],accounts:{key:{id:p.id,worldId:w.id}}});writeFileSync(dir+'/world.json',raw);
    let store=openStore(dir,100),world=store.data.worlds[0],player=world.players.a;
    assert.equal(readFileSync(dir+'/world.json.v3.bak','utf8'),raw);assert.equal(player.prologue,2);
    const mage=world.story.mages[1];player.x=mage.x;player.y=mage.y;interactStory(world,player,100);cast(world,player,'haste',100);store.save();
    store=openStore(dir,8000);world=store.data.worlds[0];player=world.players.a;
    assert.deepEqual(player.magic.known,['haste']);assert.deepEqual(world.story.communities.forest.fragments,['haste']);assert.equal(player.magic.cooldowns.haste,18100);
    storyTick(world,.1,8000,new Set());assert.equal(player.magic.effects.haste,undefined);assert.equal(player.magic.mana,75);
    assert.equal(join(world,'a','Other','city'),player);assert.equal(player.communityId,'forest');
  }finally{rmSync(dir,{recursive:true,force:true});}
});
