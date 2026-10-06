// Deterministic economy audit, not an autonomous player or a campaign playtest.
import {writeFileSync} from 'node:fs';
import {BALANCE,supplyLoot,nextWaveLevel,workerSeconds,workerYield} from '../src/balance.mjs';
import {WEAPONS} from '../src/adventure.mjs';
import {createWorld} from '../src/world.mjs';
import {supplyForecast} from '../src/population.mjs';
const rolls=Array.from({length:16},(_,i)=>supplyLoot(String.fromCharCode(64+i))),averageAmmo=rolls.reduce((n,r)=>n+r.ammo,0)/16;
const combat=[];
for(const [weapon,gun] of Object.entries(WEAPONS))for(const level of [1,2,3])for(const accuracy of [1,.7]){
 const hp=34+level*34,shots=Math.ceil(hp/gun.damage)/accuracy;
 combat.push({weapon,level,accuracy,hp,expectedSpent:Number(shots.toFixed(2)),averageLoot:averageAmmo,netAmmo:Number((averageAmmo-shots).toFixed(2))});
}
const w=createWorld(1000),c=w.communities[0];c.settlers=2;
w.walls=[{kind:'garden',communityId:c.id,hp:160,x:40,y:60},{kind:'well',communityId:c.id,hp:300,x:44,y:60}];
const food=supplyForecast(w,c);
const report={version:'0.20',method:'Deterministic theoretical audit; normal horde enemies, no bosses, no movement, armor, AI, network or human playtest',waves:{firstSeconds:BALANCE.firstWaveMs/1000,daySeconds:BALANCE.dayWaveSeconds,nightSeconds:BALANCE.nightWaveSeconds,levels:Array.from({length:12},(_,i)=>nextWaveLevel(i))},loot:{averageAmmo,previousAverageAmmo:9,foodPer16:rolls.reduce((n,r)=>n+r.food,0),waterPer16:rolls.reduce((n,r)=>n+r.water,0),medicalPer16:rolls.reduce((n,r)=>n+r.medical,0)},combat,survival:{minutesFromFullWithoutSupplies:{food:100/BALANCE.hungerPerSecond/60,water:100/BALANCE.thirstPerSecond/60},twoResidentsGardenAndNearbyWell:food},workers:[0,1,2].map(level=>({level,extractSeconds:workerSeconds(level),woodPerHitAtTech0:workerYield('tree',0),woodPerHitAtTech3:workerYield('tree',3)}))};
writeFileSync('docs/BALANCE_020.json',JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));
