import {randomUUID} from 'node:crypto';
import {solid} from './navigation.mjs';
import {clearSight} from './story.mjs';

const distance=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
export function campaignStage(w,now){
 const day=Math.max(1,1+Math.floor((now-w.startedAt)/86400000));
 const index=day<=3?0:day<=10?1:day<=20?2:day<=27?3:4;
 return {day,index,name:['Llegada','Exploración','Guerra','Asedio final','El sello cede'][index],threat:[2,3,4,5,6][index]};
}
export function initializeInteriors(w,a){
 if(a.interiorsVersion||w.legacy)return;
 for(const site of a.sites.filter(s=>['hospital','laboratory'].includes(s.kind))){
  const own=o=>String(o.id).startsWith(site.id+'-courtyard-');
  if([...w.walls,...(w.resources||[]),...Object.values(w.players),...w.zombies,...(w.workers||[])].some(p=>Math.abs(p.x-site.x)<7&&Math.abs(p.y-site.y)<7))continue;
  if(w.obstacles.some(o=>!own(o)&&Math.abs(o.x-site.x)<o.sx+6&&Math.abs(o.y-site.y)<o.sy+6))continue;
  if(w.communities.some(c=>distance(c,site)<34)||w.story?.mages?.some(m=>distance(m.home,site)<10)||w.story?.seal&&distance(w.story.seal,site)<12)continue;
  if(site.x<8||site.y<8||site.x>w.size-8||site.y>w.size-8)continue;
  const parts=[[-5,0,.5,5],[5,0,.5,5],[-3,-5,2,.5],[3,-5,2,.5],[-3,5,2,.5],[3,5,2,.5],[-3,0,2,.3],[3,0,2,.3]];
  parts.forEach(([dx,dy,sx,sy],i)=>{
   const id=site.id+'-courtyard-'+i;
   if(!w.obstacles.some(o=>o.id===id))w.obstacles.push({id,x:site.x+dx,y:site.y+dy,sx,sy,landmark:site.kind,height:2.2});
  });
  site.interior={version:1,entry:{x:site.x-2.5,y:site.y+2.5},objective:{x:site.x+2.5,y:site.y-2.5}};
 }
 a.interiorsVersion=1;
}

export function encounterHint(site,elapsed=0){
 const e=site.encounter;
 if(!e)return site.kind==='hospital'?'E en la radio de recepción: iniciar rescate':'E en el cuadro eléctrico: iniciar recuperación';
 if(e.status==='ready')return 'E junto al objetivo interior: recoger informe y suministros';
 return `${e.title}: elimina ${e.remaining} infectados y permanece junto al ${site.kind==='hospital'?'paciente':'terminal'} (${Math.floor(e.progress)}/${e.required} s). Quedan ${Math.max(0,Math.ceil(e.endsAt-elapsed))} s.`;
}

// Return null only when the existing expedition reward can proceed.
export function expeditionGate(w,p,site,now){
 if(!site.interior)return null;
 const a=w.adventure,fail=message=>{p.buildError=message;return false;};
 if((site.readyAt||0)>now)return fail(`Zona registrada. Vuelve en ${Math.ceil((site.readyAt-now)/1000)} s.`);
 const e=site.encounter;
 if(e){
  if(e.communityId!==p.communityId)return fail('Otra comunidad está realizando esta expedición.');
  if(e.status!=='ready')return fail(encounterHint(site,a.elapsed));
  if(distance(p,site.interior.objective)>2||!clearSight(w,p,site.interior.objective))return fail('Acércate al objetivo de la sala interior para recoger el informe.');
  return null;
 }
 if(p.cargo)return fail('Entrega primero el informe que llevas en tu bóveda.');
 if(distance(p,site.interior.entry)>2||!clearSight(w,p,site.interior.entry))return fail(encounterHint(site));
 const phase=campaignStage(w,now),spots=[];
 for(const [dx,dy] of [[-2,-2],[2,2],[-2,7],[2,-7],[-3,8],[3,-8]]){
  const point={x:site.x+dx,y:site.y+dy};
  if(!solid(w,point.x,point.y)&&!Object.values(w.players).some(q=>q.alive&&distance(q,point)<2)&&!w.zombies.some(q=>distance(q,point)<1.5))spots.push(point);
 }
 if(spots.length<phase.threat||w.zombies.length+phase.threat>96)return fail('La zona está demasiado ocupada para iniciar el encuentro. Despeja los accesos.');
 const id=randomUUID(),level=Math.min(3,1+Math.floor(phase.index/2)),hp=34+level*18;
 for(const point of spots.slice(0,phase.threat))w.zombies.push({id:randomUUID(),...point,communityId:p.communityId,encounterId:id,hp,maxHp:hp,level,variant:site.kind==='laboratory'?'runner':'walker',attack:0,boss:false});
 const title=site.kind==='hospital'?['Una voz entre camillas','Último turno','Evacuación bajo fuego','El último refugio','Nadie queda atrás'][phase.index]:['Archivo dormido','Ecos del Umbral','Datos en disputa','Protocolo de emergencia','Antes del silencio'][phase.index];
 site.encounter={id,communityId:p.communityId,title,phase:phase.name,status:'active',progress:0,required:site.kind==='hospital'?12:20,remaining:phase.threat,endsAt:a.elapsed+180};
 p.noiseUntil=now+20000;p.actionMessage='Entra en la sala interior. '+encounterHint(site,a.elapsed);return true;
}
export function expeditionsTick(w,online,dt){
 const a=w.adventure;
 for(const site of a.sites){
  const e=site.encounter;if(!e)continue;
  if(a.elapsed>=e.endsAt){w.zombies=w.zombies.filter(z=>z.encounterId!==e.id);site.encounter=null;continue;}
  if(e.status==='ready')continue;
  e.remaining=w.zombies.filter(z=>z.encounterId===e.id&&z.hp>0).length;
  const point=site.interior.objective;
  const present=Object.values(w.players).some(p=>p.alive&&online.has(p.id)&&p.communityId===e.communityId&&distance(p,point)<=2&&clearSight(w,p,point));
  const danger=w.zombies.some(z=>z.hp>0&&distance(z,point)<6);
  if(present&&!danger&&e.remaining===0)e.progress=Math.min(e.required,e.progress+dt);
  if(e.progress>=e.required)e.status='ready';
 }
}
