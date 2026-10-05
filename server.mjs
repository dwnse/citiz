import {profileFor,settleRewards,cosmetics,cosmeticAction} from './src/rewards.mjs';
import http from 'node:http';
import {readFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {randomUUID} from 'node:crypto';
import {performance} from 'node:perf_hooks';
import {createWorld,join,action,tick,snapshot,CONFIG} from './src/world.mjs';
import {openStore} from './src/storage.mjs';
import {navigationMetrics} from './src/navigation.mjs';
import {capacity,members} from './src/communities.mjs';
const root=fileURLToPath(new URL('.',import.meta.url));
export function createServer({directory=root+'data',clock=()=>Date.now(),mode='development'}={}){
  if(!['development','production'].includes(mode))throw Error('Modo desconocido');
  const store=openStore(directory,clock(),mode),{worlds,accounts}=store.data;
  const world=worlds[0];
  const sessions=new Map(),streams=new Map(),inputs=new Map(),actionRates=new Map();let cpuMs=0,bytes=0;
  function save(){settleRewards(store.data);store.save();}
  function view(w,id,present,now){return {...snapshot(w,id,present,now),cosmetics:cosmetics(store.data,w.id,id)};}
  function online(w=world){return new Set([...streams.keys()].filter(id=>w.players[id]));}
  function send(res,status,obj){res.writeHead(status,{'Content-Type':'application/json'});res.end(JSON.stringify(obj));}
  const server=http.createServer(async(req,res)=>{
    const url=new URL(req.url,'http://localhost');
    const origin=req.headers.origin;
    if(origin&&origin!==`http://${req.headers.host}`)return send(res,403,{error:'Origen no permitido'});
    try {
      if(req.method==='GET'&&url.pathname==='/api/protocol')return send(res,200,{protocol:1,saveVersion:6,build:'0.14.0',features:['harvesting','vault-rebuild','adventure','typed-materials','patient-zero','boss-variants','population','workers','incidents','cosmetics'],transport:'http-sse',tickHz:CONFIG.tick,snapshotHz:10,coordinates:'x,y -> Godot x,0,z'});
      if(req.method==='GET'&&url.pathname==='/api/worlds')return send(res,200,{worlds:worlds.map(w=>({id:w.id,name:w.name,phase:w.phase,remaining:Math.max(0,w.startedAt+CONFIG.duration-clock()),members:Object.keys(w.players).length,capacity:capacity(w),online:online(w).size,communities:w.communities.map(c=>({id:c.id,name:c.name,region:c.region,color:c.color,members:members(w,c).length,capacity:10,eliminated:c.eliminated,vaultAlive:c.vault.hp>0}))})),mode});
      const token=req.headers.cookie?.split(';').map(x=>x.trim()).find(x=>x.startsWith('cerco='))?.slice(6),session=sessions.get(token),id=session?.id;
      const current=worlds.find(w=>w.id===session?.worldId);
      if(req.method==='GET'&&url.pathname==='/api/events'){
        if(!id||!current||(url.searchParams.has('worldId')&&url.searchParams.get('worldId')!==current.id))return send(res,401,{error:'Ingresa primero'});
        streams.get(id)?.end();res.writeHead(200,{'Content-Type':'text/event-stream','Cache-Control':'no-cache','Connection':'keep-alive'});streams.set(id,res);
        res.write(`data: ${JSON.stringify(view(current,id,online(current),clock()))}\n\n`);
        req.on('close',()=>{if(streams.get(id)===res){streams.delete(id);inputs.delete(id);}});return;
      }
      if(req.method==='POST'){
        let body='';for await(const chunk of req){body+=chunk;if(body.length>2048){send(res,413,{error:'Mensaje demasiado grande'});return;}}
        const msg=JSON.parse(body);
        if(!msg||Array.isArray(msg)||typeof msg!=='object')return send(res,400,{error:'Se requiere un objeto JSON'});
        if(url.pathname==='/api/worlds'){
          if(mode!=='development')return send(res,403,{error:'Creación pública deshabilitada'});
          if(worlds.length>=8)return send(res,409,{error:'Límite local de 8 mundos alcanzado'});
          const fresh=createWorld(clock(),mode);fresh.name=String(msg.name||`Cerco ${worlds.length+1}`).trim().slice(0,40)||'Cerco';worlds.push(fresh);save();return send(res,201,{world:{id:fresh.id,name:fresh.name}});
        }
        if(url.pathname==='/api/join'){
          let identity=typeof msg.key==='string'&&Object.hasOwn(accounts,msg.key)?accounts[msg.key]:null;
          if(msg.key&&!identity)return send(res,401,{error:'Clave de reconexión inválida'});
          if(identity&&msg.worldId&&identity.worldId!==msg.worldId)return send(res,403,{error:'La identidad pertenece a otro mundo'});
          const chosen=worlds.find(w=>w.id===(identity?.worldId||msg.worldId||worlds[0].id));
          if(!chosen)return send(res,404,{error:'Mundo inexistente'});
          const prior=typeof msg.accountKey==='string'&&Object.hasOwn(accounts,msg.accountKey)?accounts[msg.accountKey]:null;
          if(msg.accountKey&&!prior)return send(res,401,{error:'Perfil de cuenta inválido'});
          const profileId=identity?.profileId||identity?.id||prior?.profileId||prior?.id||randomUUID();
          // Reusing an account in one world reconnects its existing slot.
          identity??=Object.values(accounts).find(a=>a.worldId===chosen.id&&(a.profileId||a.id)===profileId)||null;
          let playerId;
          if(identity)playerId=identity.id;
          else {if(Object.keys(chosen.players).length>=capacity(chosen)||chosen.phase!=='active')return send(res,409,{error:'Mundo cerrado o lleno'});playerId=randomUUID();}
          const wasEmpty=!Object.keys(chosen.players).length;
          const p=join(chosen,playerId,msg.name,msg.communityId||'forest'),key=msg.key||Object.entries(accounts).find(([,a])=>a.id===playerId&&a.worldId===chosen.id)?.[0]||randomUUID();accounts[key]={id:playerId,worldId:chosen.id,profileId};p.appearance=profileFor(store.data,accounts[key]).equipped||'standard';
          if(wasEmpty){chosen.startedAt=clock();chosen.nextWave=clock()+45000;}
          for(const [old,s]of sessions)if(s.id===playerId)sessions.delete(old);
          streams.get(playerId)?.end();streams.delete(playerId);inputs.delete(playerId);
          const nextSession=randomUUID();sessions.set(nextSession,{id:playerId,worldId:chosen.id});save();res.setHeader('Set-Cookie',`cerco=${nextSession}; HttpOnly; SameSite=Strict; Path=/`);
          return send(res,200,{id:playerId,key,seq:p.seq,worldId:chosen.id,communityId:p.communityId});
        }
        if(!id||!current||!streams.has(id))return send(res,401,{error:'Cliente desconectado'});
        if(msg.worldId&&msg.worldId!==current.id)return send(res,403,{error:'La sesión cambió de mundo'});
        if(url.pathname==='/api/input'){
          if(!Number.isFinite(msg.x)||!Number.isFinite(msg.y)||!Number.isFinite(msg.angle))return send(res,400,{error:'Entrada inválida'});
          const prev=inputs.get(id);if(prev&&clock()-prev.at<20)return send(res,429,{error:'Frecuencia excesiva'});
          inputs.set(id,{x:msg.x,y:msg.y,angle:msg.angle,at:clock()});return send(res,200,{ok:true});
        }
        if(url.pathname==='/api/action'){
          let rate=actionRates.get(id);if(!rate||clock()-rate.at>=1000){rate={at:clock(),count:0};actionRates.set(id,rate);}
          if(++rate.count>40)return send(res,429,{error:'Demasiadas acciones por segundo'});
          const player=current.players[id];player.buildError='';player.actionMessage='';
          const ok=msg.type==='cosmetic'?cosmeticAction(store.data,current,player,msg):action(current,player,msg,clock(),online(current));
          if(ok&&(current.phase==='victory'||msg.type==='cosmetic'))save();
          return send(res,200,{ok,message:ok?(player.actionMessage||{build:'Estructura construida',build_row:'Fila construida',repair:'Estructura reparada',upgrade_structure:'Mejora completada',scavenge:'Recogidos 25 materiales y 6 balas',dismantle:'Estructura desmontada',reload:'Recargando…'}[msg.type]||''):player.buildError||({reload:'El cargador está lleno, falta munición o ya estás recargando.',scavenge:'Acércate a una ruina disponible para recoger suministros.',use:'Acércate a la estructura. Comprueba sus existencias y tus necesidades.'}[msg.type]||'No disponible: comprueba distancia, materiales y estado del objetivo.')});
        }
      }
      if(url.pathname==='/api/metrics')return send(res,200,{tickMs:cpuMs,outboundBytes:bytes,clients:streams.size,zombies:worlds.reduce((n,w)=>n+w.zombies.length,0),tick:world.tick,worlds:worlds.map(w=>({id:w.id,...navigationMetrics(w)}))});
      const files={'/':'index.html','/game.js':'game.js','/style.css':'style.css'};const file=files[url.pathname];
      if(req.method==='GET'&&file){res.writeHead(200,{'Content-Type':file.endsWith('.js')?'text/javascript':file.endsWith('.css')?'text/css':'text/html'});res.end(readFileSync(root+'public/'+file));return;}
      send(res,404,{error:'No encontrado'});
    }catch(e){send(res,400,{error:e.message});}
  });
  let previousTime=performance.now(),accumulator=0;
  const timer=setInterval(()=>{
    const start=performance.now(),elapsed=(start-previousTime)/1000;previousTime=start;
    // Keep simulation time independent of timer granularity. Bound catch-up work
    // after process stalls; do not turn a long pause into a movement teleport.
    accumulator+=Math.min(.25,elapsed);
    const steps=Math.min(5,Math.floor(accumulator*CONFIG.tick));
    accumulator-=steps/CONFIG.tick;
    for(const w of worlds){
      const present=online(w),before=Math.floor(w.tick/3);
      for(let step=0;step<steps;step++)tick(w,inputs,present,1/CONFIG.tick,clock());
      if(Math.floor(w.tick/3)!==before)for(const id of present){
        const res=streams.get(id);if(res.writableLength>1000000){res.end();streams.delete(id);continue;}
        const data=`data: ${JSON.stringify(view(w,id,present,clock()))}\n\n`;bytes+=Buffer.byteLength(data);res.write(data);
      }
    }
    if(steps)cpuMs=(performance.now()-start)/steps;
  },10);
  const saver=setInterval(save,5000);
  return {server,world,worlds,save,close:()=>{clearInterval(timer);clearInterval(saver);save();for(const res of streams.values())res.end();return new Promise(r=>server.close(r));}};
}
if(process.argv[1]===fileURLToPath(import.meta.url)){
  const app=createServer({directory:process.env.DATA_DIR||root+'data',mode:process.env.MODE||'development'}),port=Number(process.env.PORT||3000);app.server.listen(port,'127.0.0.1',()=>console.log(`EL CERCO · http://127.0.0.1:${port}`));
  for(const signal of ['SIGINT','SIGTERM'])process.on(signal,async()=>{await app.close();process.exit(0);});
}

