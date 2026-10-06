// Reproducible server simulation; no network clients or graphics in this measurement.
import {performance} from 'node:perf_hooks';
import {writeFileSync} from 'node:fs';
import {createWorld,join,tick} from '../src/world.mjs';
const w=createWorld(1000),online=new Set(),samples=[];
w.obstacles=[];w.resources=[];w.resourceLayout=2;w.nearbyResourcesVersion=1;w.nextWave=1e12;
for(const c of w.communities){
 const p=join(w,c.id,c.id,c.id);online.add(p.id);p.hp=10000;c.settlers=8;c.workforce={food:30,water:30,fedUntil:1e12};
 for(let i=0;i<8;i++){
  const x=c.x-18+(i%4)*12,y=c.y+10+Math.floor(i/4)*10;
  w.walls.push({id:c.id+'-mill-'+i,kind:'sawmill',communityId:c.id,x,y,hp:220,stock:0});
  if(i<4)w.walls.push({id:c.id+'-home-'+i,kind:'shelter',communityId:c.id,x,y:c.y-10,hp:300});
  w.resources.push({id:c.id+'-tree-'+i,kind:'tree',x:x+4,y:y+2,hits:50,maxHits:50});
 }
}
for(let i=0;i<1800;i++){const start=performance.now();tick(w,new Map(),online,1/30,2000+i*1000/30);samples.push(performance.now()-start);}
samples.sort((a,b)=>a-b);
const result={scenario:'60 simulated seconds, 32 residents, 48 buildings, four online agents; no zombies, network or render',workers:w.workers.length,delivered:w.walls.reduce((n,b)=>n+(b.stock||0),0),meanTickMs:samples.reduce((a,b)=>a+b,0)/samples.length,p95TickMs:samples[Math.floor(samples.length*.95)],maxTickMs:samples.at(-1)};
writeFileSync('docs/performance-workers-018.json',JSON.stringify(result,null,2));console.log(result);
