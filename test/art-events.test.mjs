import test from 'node:test';
import assert from 'node:assert/strict';
import {damageInfected,zombieLoot} from '../src/loot.mjs';
test('death presentation is emitted once without making a resurrected enemy reusable',()=>{
  const w={drops:[],fallen:[],effects:[]};
  const z={id:'raised',hp:28,maxHp:68,x:4,y:8,reanimated:true};
  assert.equal(damageInfected(w,z,28,1234,'forest'),true);
  damageInfected(w,z,28,1235,'forest');zombieLoot(w,z,'forest',1236);
  assert.equal(w.drops.length,1);
  assert.equal(w.fallen.length,0);
  assert.deepEqual(w.effects,[{id:'death-raised-1234',power:'death',actorId:'raised',x:4,y:8,life:2}]);
});
