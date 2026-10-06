// Mixed two-minute local soak. Synthetic durable bases and players keep the load active.
// Run explicitly: node tools/benchmark.mjs. Kept outside test-runner discovery.
import {mkdtempSync,rmSync,writeFileSync,mkdirSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {performance} from 'node:perf_hooks';
import {createServer} from '../server.mjs';
import {solid} from '../src/navigation.mjs';
import {spawnWave} from '../src/world.mjs';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const percentile=(values,p)=>[...values].sort((a,b)=>a-b)[Math.floor((values.length-1)*p)]||0;
const reports=[];
for(const count of [40]){
  const directory=mkdtempSync(join(tmpdir(),'cerco-load-')),app=createServer({directory}),clients=[],errors=[];
  let bytes=0,readers=[];
  try{
    await new Promise(r=>app.server.listen(0,'127.0.0.1',r));const base=`http://127.0.0.1:${app.server.address().port}`;
    for(let i=0;i<count;i++){
      const response=await fetch(base+'/api/join',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name:'Load '+i,communityId:['forest','mountain','city','underground'][Math.floor(i/10)]})});
      if(!response.ok)throw Error('Join failed '+response.status);
      const info=await response.json(),cookie=response.headers.get('set-cookie').split(';')[0],controller=new AbortController();
      const events=await fetch(base+'/api/events?delta=1',{headers:{cookie},signal:controller.signal});if(!events.ok)throw Error('SSE failed');
      clients.push({cookie,id:info.id,controller,seq:0});
      readers.push((async()=>{try{for await(const data of events.body)bytes+=data.length;}catch(e){if(!controller.signal.aborted)errors.push(e.message);}})());
    }
    const w=app.world;
    for(const p of Object.values(w.players)){p.hp=100000;p.reserve=5000;}
    for(const c of w.communities){
      c.vault.hp=100000;c.settlers=8;c.workforce={food:30,water:30,fedUntil:Date.now()+300000};
      for(let i=0;i<4;i++){const x=c.x-12+i*8,y=c.y-10;if(!solid(w,x,y,2.3))w.walls.push({id:c.id+'-load-home-'+i,kind:'shelter',communityId:c.id,x,y,hp:10000,stock:0});}
      for(let i=0;i<8;i++){
        const x=c.x-15+(i%4)*10,y=c.y+8+Math.floor(i/4)*8;
        if(solid(w,x,y,2.3)||solid(w,x+3.5,y+3,1))continue;
        w.walls.push({id:c.id+'-load-mill-'+i,kind:'sawmill',communityId:c.id,x,y,hp:10000,stock:0});
        w.resources.push({id:c.id+'-load-tree-'+i,kind:'tree',x:x+3.5,y:y+3,hits:50,maxHits:50});
      }
    }
    spawnWave(app.world,3,new Set(clients.map(c=>c.id)));
    const zombies=app.world.zombies.length,start=performance.now(),tickStart=app.world.tick,latencies=[],ticks=[],trafficStart=bytes;
    for(let sample=0;sample<1200;sample++){
      if(sample%300===0)console.log('Mixed load '+sample+'/1200; workers '+(app.world.workers?.length||0));
      const batch=performance.now();
      await Promise.all(clients.map(async(c,i)=>{
        const sent=performance.now();
        const r=await fetch(base+'/api/input',{method:'POST',headers:{cookie:c.cookie,'Content-Type':'application/json'},body:JSON.stringify({x:sample%20<10?.4:-.4,y:0,angle:i})});
        await r.text();latencies.push(performance.now()-sent);if(!r.ok)errors.push('input '+r.status);
        if(sample%3===0){const shot=await fetch(base+'/api/action',{method:'POST',headers:{cookie:c.cookie,'Content-Type':'application/json'},body:JSON.stringify({type:app.world.players[c.id].ammo>0?'shoot':'reload',angle:i,seq:++c.seq})});await shot.text();if(!shot.ok)errors.push('shoot '+shot.status);}
      }));
      const metrics=await fetch(base+'/api/metrics').then(r=>r.json());ticks.push(metrics.tickMs);
      await sleep(Math.max(0,100-(performance.now()-batch)));
    }
    const seconds=(performance.now()-start)/1000;
    reports.push({clients:count,zombies,workers:app.world.workers?.length||0,buildings:app.world.walls.length,delivered:app.world.walls.reduce((n,b)=>n+(b.stock||0),0),seconds:Number(seconds.toFixed(2)),ticksPerSecond:Number(((app.world.tick-tickStart)/seconds).toFixed(1)),sampledTickP95ms:Number(percentile(ticks,.95).toFixed(2)),inputP95ms:Number(percentile(latencies,.95).toFixed(2)),receivedKiBPerSecond:Number(((bytes-trafficStart)/seconds/1024).toFixed(1)),errors:errors.length});
    console.log(reports.at(-1));
  }finally{for(const c of clients)c.controller.abort();await Promise.allSettled(readers);await app.close();rmSync(directory,{recursive:true,force:true});}
}
mkdirSync('docs',{recursive:true});
writeFileSync('docs/CARGA_MIXTA_017.json',JSON.stringify({date:new Date().toISOString(),node:process.version,platform:process.platform,scenario:'40 HTTP/SSE clients, AI horde, 32 residents, durable synthetic bases and players; two minutes, delta replication, loopback, no graphics',reports},null,2));
if(reports.some(r=>r.errors))process.exitCode=1;
