import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createWorld,join,snapshot} from '../src/world.mjs';
import {initializeAdventure} from '../src/adventure.mjs';
import {initializeMountainScenery} from '../src/mountain-scenery.mjs';
import {solid,findPath} from '../src/navigation.mjs';

test('Cumbre has blocked ravines, open crossings, snow pines and accessible entrances',()=>{
 const w=createWorld(0),p=join(w,'cumbre','Guardia','mountain');
 snapshot(w,p.id,new Set([p.id]),0);
 assert.equal(w.mountainSceneryVersion,1);
 assert.ok(w.obstacles.filter(o=>o.scenery==='mountain-pine').length>40);
 const river=w.obstacles.filter(o=>o.scenery==='mountain-water');assert.ok(river.length>20);
 for(const o of river)assert.ok(solid(w,o.x,o.y));
 for(const y of [160,188])assert.equal(solid(w,23+Math.sin((y-110)*.08)*5,y),false);
 assert.ok(findPath(w,{x:50,y:169},{x:50,y:207},1).length);
 const prior=JSON.stringify({obstacles:w.obstacles,resources:w.resources,walls:w.walls});
 snapshot(w,p.id,new Set([p.id]),0);
 assert.equal(JSON.stringify({obstacles:w.obstacles,resources:w.resources,walls:w.walls}),prior);
});

test('mountain migration preserves saved objects and never grows a core over its residents',()=>{
 const w=createWorld(0);initializeAdventure(w);
 w.resources=[{id:'saved-ore',kind:'rock',x:23,y:151,hits:2}];
 w.walls=[{id:'saved-home',kind:'shelter',x:38,y:148,hp:100}];
 w.players={a:{id:'a',communityId:'mountain',x:53,y:160,alive:true}};
 const prior=JSON.stringify({resources:w.resources,walls:w.walls,players:w.players});
 initializeMountainScenery(w);
 assert.equal(JSON.stringify({resources:w.resources,walls:w.walls,players:w.players}),prior);
 assert.equal(w.communities.find(c=>c.id==='mountain').vault.radius,2.2);
 for(const o of w.obstacles.filter(o=>o.scenery?.startsWith('mountain-'))){
  assert.ok(Math.abs(o.x-23)>=o.sx+1||Math.abs(o.y-151)>=o.sy+1);
  assert.ok(Math.abs(o.x-38)>=o.sx+2||Math.abs(o.y-148)>=o.sy+2);
 }
 const legacy={legacy:true,obstacles:[]};initializeMountainScenery(legacy);assert.deepEqual(legacy.obstacles,[]);
});
