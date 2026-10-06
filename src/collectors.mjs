import {clearSight} from './story.mjs';
import {addMaterials} from './inventory.mjs';

export function initializeCollectors(w){
 if(w.collectors||w.legacy)return;
 const rooms=[];
 for(const [id,x,name] of [['west',79,'Galería de las raíces'],['east',131,'Cámara del Umbral']]){
  const parts=[[-13,0,.5,6],[13,0,.5,6],[0,-6,13,.5],[0,6,13,.5],[-4,-3,1,1],[4,3,1,1]];
  // A migration never encloses existing people, buildings or harvestable nodes.
  const occupied=[...w.walls,...(w.resources||[]),...Object.values(w.players),...w.zombies,...(w.workers||[])].some(p=>Math.abs(p.x-x)<15&&Math.abs(p.y-105)<8);
  if(occupied||(w.obstacles||[]).some(o=>Math.abs(o.x-x)<o.sx+14&&Math.abs(o.y-105)<o.sy+7))continue;
  const room={id,name,x,y:105,cache:{x,y:107,readyAt:0},valve:{x,y:102},purgedUntil:0};rooms.push(room);
  for(const [i,[dx,dy,sx,sy]] of parts.entries())w.obstacles.push({id:'collector-'+id+'-'+i,x:x+dx,y:105+dy,sx,sy,landmark:'collector'});
 }
 w.collectors={version:1,rooms};
}
export function collectorInteraction(w,p,now){
 const room=w.collectors?.rooms.find(r=>Math.abs(r.x-p.x)<12&&Math.abs(r.y-p.y)<5.5);
 if(!room)return null;
 if(Math.hypot(room.valve.x-p.x,room.valve.y-p.y)<=2.5&&clearSight(w,p,room.valve)){
  if(room.purgedUntil>now){p.buildError='La ventilación ya está activa.';return false;}
  room.purgedUntil=now+120000;p.actionMessage='Ventilación activada durante 120 s. Registra el armario y busca la salida.';return true;
 }
 if(Math.hypot(room.cache.x-p.x,room.cache.y-p.y)<=2.5&&clearSight(w,p,room.cache)){
  if(room.purgedUntil<=now){p.buildError='Primero abre la válvula de ventilación señalada en azul.';return false;}
  if(room.cache.readyAt>now){p.buildError='Armario vacío: vuelve en '+Math.ceil((room.cache.readyAt-now)/1000)+' s.';return false;}
  room.cache.readyAt=now+180000;addMaterials(p,'scrap',12);addMaterials(p,'components',2);p.reserve+=12;p.noiseUntil=now+20000;
  p.actionMessage='Armario del colector: 12 chatarra, 2 componentes y 12 balas. El ruido atrae infectados.';return true;
 }
 return null;
}
export function collectorsTick(w,online,dt,now,hurt){
 for(const p of Object.values(w.players)){
  if(!p.alive||!online.has(p.id))continue;
  const room=w.collectors?.rooms.find(r=>Math.abs(r.x-p.x)<12&&Math.abs(r.y-p.y)<5.5);
  if(!room||room.purgedUntil>now)continue;
  p.stamina=Math.max(0,(p.stamina??100)-20*dt);
  if(p.stamina===0)hurt(w,p,4*dt,now);
 }
}
