import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createWorld,join,snapshot} from '../src/world.mjs';
import {initializeResources} from '../src/harvesting.mjs';
import {initializeForestScenery} from '../src/forest-scenery.mjs';
import {solid,findPath} from '../src/navigation.mjs';
import {initializeAdventure} from '../src/adventure.mjs';

test('forest scenery leaves the base, roads and established objects accessible',()=>{
 const w=createWorld(0),p=join(w,'forest-art','Forest');
 snapshot(w,p.id,new Set([p.id]),0);
 const trees=w.obstacles.filter(o=>o.scenery==='forest-tree');
 assert.ok(trees.length>40);
 for(const tree of trees){
  assert.ok(Math.hypot(tree.x-50,tree.y-50)>=22);
  assert.ok(Math.abs(tree.x-50)>=5&&Math.abs(tree.y-50)>=5);
  assert.equal(solid(w,tree.x,tree.y),true);
  assert.ok(w.resources.every(r=>Math.hypot(tree.x-r.x,tree.y-r.y)>=3.2));
 }
 assert.ok(findPath(w,{x:50,y:64},{x:50,y:95},1).length);
 const before=JSON.stringify({obstacles:w.obstacles,resources:w.resources,walls:w.walls});
 snapshot(w,p.id,new Set([p.id]),0);
 snapshot(w,p.id,new Set([p.id]),0);
 assert.equal(JSON.stringify({obstacles:w.obstacles,resources:w.resources,walls:w.walls}),before);
});

test('saved worlds gain scenery without moving residents, buildings or resources',()=>{
 const w=createWorld(0);
 initializeAdventure(w);
 w.resources=[{id:'old-resource',kind:'tree',x:9,y:9,hits:2}];
 w.walls=[{id:'old-building',kind:'workshop',x:13,y:13,hp:200}];
 w.players={a:{id:'a',x:17,y:17}};
 const existing=JSON.stringify({resources:w.resources,walls:w.walls,players:w.players});
 initializeForestScenery(w);
 assert.equal(JSON.stringify({resources:w.resources,walls:w.walls,players:w.players}),existing);
 for(const tree of w.obstacles.filter(o=>o.scenery==='forest-tree')){
  assert.ok(Math.hypot(tree.x-13,tree.y-13)>=5);
  assert.ok(Math.hypot(tree.x-17,tree.y-17)>=4);
 }
 const legacy={legacy:true,obstacles:[]};
 initializeForestScenery(legacy);
 assert.deepEqual(legacy.obstacles,[]);
});

test('deep river is blocked while both bridge approaches remain walkable',()=>{
 const w=createWorld(0),p=join(w,'river-check','Forest');
 snapshot(w,p.id,new Set([p.id]),0);
 const water=w.obstacles.filter(o=>o.scenery==='forest-water');
 assert.ok(water.length>20);
 for(const cell of water)assert.equal(solid(w,cell.x,cell.y),true);
 assert.equal(solid(w,50,84+Math.sin(50*.07)*4),false);
 assert.equal(solid(w,10.5+Math.cos(50*.095)*2.5,50),false);
 assert.ok(findPath(w,{x:50,y:76},{x:50,y:93},1).length);
});

test('v1 scenery migrates once and an occupied core retains its original footprint',()=>{
 const w=createWorld(0);
 initializeAdventure(w);
 w.forestSceneryVersion=1;
 w.obstacles.push({id:'forest-scenery-old-tree',x:42,y:42,sx:.3,sy:.3,scenery:'forest-tree'});
 w.players={a:{id:'a',x:53,y:50}};
 w.resources=[{id:'saved-wood',kind:'tree',x:30,y:30,hits:3}];
 w.walls=[{id:'saved-wall',kind:'wall',x:40,y:39,hp:100}];
 const saved=JSON.stringify({players:w.players,resources:w.resources,walls:w.walls});
 initializeForestScenery(w);
 assert.equal(w.forestSceneryVersion,2);
 assert.equal(w.obstacles.some(o=>o.id==='forest-scenery-old-tree'),false);
 assert.equal(w.communities.find(c=>c.id==='forest').vault.radius,2.2);
 assert.equal(JSON.stringify({players:w.players,resources:w.resources,walls:w.walls}),saved);
 const scenery=JSON.stringify(w.obstacles);
 initializeForestScenery(w);
 assert.equal(JSON.stringify(w.obstacles),scenery);
});
