// Shared tuning and diagnostics. Existing inventories are never rescaled.
export const BALANCE=Object.freeze({firstWaveMs:90000,dayWaveSeconds:60,nightWaveSeconds:45,hungerPerSecond:.04,thirstPerSecond:.07});
export const nextWaveLevel=wave=>Math.min(3,1+Math.floor(Math.max(0,wave)/3));
export const workerSeconds=level=>Math.max(12,20-Math.max(0,Math.min(2,level||0))*4);
export const workerYield=(kind,tech)=> (kind==='tree'?6:8)+Math.max(0,Math.min(3,tech||0));
export function supplyLoot(id,boss=false){
 if(boss)return {ammo:12,food:2,water:2,medical:2};
 const roll=[...String(id)].reduce((n,c)=>n+c.charCodeAt(0),0)%16;
 return {ammo:1+roll%2,food:roll===2?2:0,water:roll===10?2:0,medical:roll===6?1:0};
}
