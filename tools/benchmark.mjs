// Run explicitly: node tools/benchmark.mjs. Kept outside test-runner discovery.
import {mkdtempSync,rmSync,writeFileSync,mkdirSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {performance} from 'node:perf_hooks';
import {createServer} from '../server.mjs';
import {spawnWave} from '../src/world.mjs';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const percentile=(values,p)=>[...values].sort((a,b)=>a-b)[Math.floor((values.length-1)*p)]||0;
const reports=[];
for(const count of [2,10,20,40]){
  const directory=mkdtempSync(join(tmpdir(),'cerco-load-')),app=createServer({directory}),clients=[],errors=[];
  let bytes=0,readers=[];
  try{
    await new Promise(r=>app.server.listen(0,'127.0.0.1',r));const base=`http://127.0.0.1:${app.server.address().port}`;
    for(let i=0;i<count;i++){
      const response=await fetch(base+'/api/join',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name:'Load '+i,communityId:['forest','mountain','city','underground'][Math.floor(i/10)]})});
      if(!response.ok)throw Error('Join failed '+response.status);
      const info=await response.json(),cookie=response.headers.get('set-cookie').split(';')[0],controller=new AbortController();
      const events=await fetch(base+'/api/events',{headers:{cookie},signal:controller.signal});if(!events.ok)throw Error('SSE failed');
      clients.push({cookie,id:info.id,controller,seq:0});
      readers.push((async()=>{try{for await(const data of events.body)bytes+=data.length;}catch(e){if(!controller.signal.aborted)errors.push(e.message);}})());
    }
    spawnWave(app.world,3,new Set(clients.map(c=>c.id)));
    const zombies=app.world.zombies.length,start=performance.now(),tickStart=app.world.tick,latencies=[],ticks=[],trafficStart=bytes;
    for(let sample=0;sample<150;sample++){
      const batch=performance.now();
      await Promise.all(clients.map(async(c,i)=>{
        const sent=performance.now();
        const r=await fetch(base+'/api/input',{method:'POST',headers:{cookie:c.cookie,'Content-Type':'application/json'},body:JSON.stringify({x:sample%20<10?.4:-.4,y:0,angle:i})});
        await r.text();latencies.push(performance.now()-sent);if(!r.ok)errors.push('input '+r.status);
        if(sample%3===0){const shot=await fetch(base+'/api/action',{method:'POST',headers:{cookie:c.cookie,'Content-Type':'application/json'},body:JSON.stringify({type:'shoot',angle:i,seq:++c.seq})});await shot.text();if(!shot.ok)errors.push('shoot '+shot.status);}
      }));
      const metrics=await fetch(base+'/api/metrics').then(r=>r.json());ticks.push(metrics.tickMs);
      await sleep(Math.max(0,100-(performance.now()-batch)));
    }
    const seconds=(performance.now()-start)/1000;
    reports.push({clients:count,zombies,seconds:Number(seconds.toFixed(2)),ticksPerSecond:Number(((app.world.tick-tickStart)/seconds).toFixed(1)),sampledTickP95ms:Number(percentile(ticks,.95).toFixed(2)),inputP95ms:Number(percentile(latencies,.95).toFixed(2)),receivedKiBPerSecond:Number(((bytes-trafficStart)/seconds/1024).toFixed(1)),errors:errors.length});
    console.log(reports.at(-1));
  }finally{for(const c of clients)c.controller.abort();await Promise.allSettled(readers);await app.close();rmSync(directory,{recursive:true,force:true});}
}
mkdirSync('docs',{recursive:true});
writeFileSync('docs/CARGA.json',JSON.stringify({date:new Date().toISOString(),node:process.version,platform:process.platform,reports},null,2));
writeFileSync('docs/CARGA_013.md',`# Prueba local de carga 0.13\n\nEjecutada ${new Date().toISOString()} con ${process.version} en ${process.platform}. Reproducir: \`node tools/benchmark.mjs\`.\n\n| Clientes | Zombis iniciales | Duración s | Ticks/s | Tick p95 muestreado ms | Entrada p95 ms | KiB/s recibidos total | Errores HTTP/red |\n|---|---|---|---|---|---|---|---|\n${reports.map(r=>`| ${r.clients} | ${r.zombies} | ${r.seconds} | ${r.ticksPerSecond} | ${r.sampledTickP95ms} | ${r.inputP95ms} | ${r.receivedKiBPerSecond} | ${r.errors} |`).join('\n')}\n\nCada cliente usa HTTP/SSE real, manda movimiento a aproximadamente 10 Hz y dispara cada tercer envío. Se leen los streams continuamente; hay una oleada de nivel 3 en las comunidades ocupadas. Ciento cincuenta muestras del último tick, no una traza de todos los ticks. Latencia medida de extremo a extremo de la petición de entrada en loopback. El tráfico es la suma de bytes de cuerpos SSE recibidos, sin cabeceras TCP/HTTP. El servidor guarda cada 5 segundos. Las pruebas usan carpetas temporales independientes.\n\nNo incluye renderizado de 40 navegadores, red externa, pérdida de paquetes, builds máximas ni una sesión prolongada. No demuestra capacidad de producción; permite detectar regresiones y estimar límites locales.\n`);
if(reports.some(r=>r.errors))process.exitCode=1;


