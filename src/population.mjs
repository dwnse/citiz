import {productionInterval} from './structures.mjs';
export const housing=(w,c)=>w.walls.filter(b=>b.kind==='shelter'&&b.hp>0&&b.communityId===c.id).length*2;
export function supplyForecast(w,c){
 const demand=Math.ceil((c.settlers||0)/2),foodPerMinute=sites(w,c,['garden']).reduce((n,b)=>n+60000/productionInterval(w,b),0),waterPerMinute=sites(w,c,['well','raincollector']).reduce((n,b)=>n+60000/productionInterval(w,b),0);
 return {demand,foodPerMinute,waterPerMinute,foodBalance:foodPerMinute-demand,waterBalance:waterPerMinute-demand};
}
export function workforce(c,now){return c.workforce??={food:0,water:0,fedUntil:now+180000};}
const sites=(w,c,kinds)=>w.walls.filter(b=>b.hp>0&&b.communityId===c.id&&kinds.includes(b.kind));
function available(w,c,key){return (c.workforce[key]||0)+sites(w,c,key==='food'?['garden']:['well','raincollector']).reduce((sum,b)=>sum+(b.stock||0),0);}
function consume(w,c,key,n){const own=Math.min(c.workforce[key]||0,n);c.workforce[key]-=own;n-=own;for(const b of sites(w,c,key==='food'?['garden']:['well','raincollector'])){const take=Math.min(b.stock||0,n);b.stock=(b.stock||0)-take;n-=take;if(!n)break;}}
export function prepareWorkforce(w,online,now){
 const assigned=new Map();
 for(const c of w.communities){
  const count=c.settlers||0,capacity=housing(w,c),jobs=sites(w,c,['sawmill','quarry']).sort((a,b)=>(b.staffPriority||0)-(a.staffPriority||0));
  const active=!online||Object.values(w.players).some(p=>p.alive&&p.communityId===c.id&&online.has(p.id));
  const state=count?workforce(c,now):{fedUntil:0};
  if(count&&active&&state.fedUntil<=now){const cost=Math.ceil(count/2);if(available(w,c,'food')>=cost&&available(w,c,'water')>=cost){consume(w,c,'food',cost);consume(w,c,'water',cost);state.fedUntil=now+60000;}}
  let workers=Math.max(0,Math.min(count,capacity)-(w.workers||[]).filter(q=>q.communityId===c.id&&q.order).length);
  for(const b of jobs){
   const resource=(w.resources||[]).find(r=>r.hits>0&&r.kind===(b.kind==='sawmill'?'tree':'rock')&&Math.hypot(r.x-b.x,r.y-b.y)<=10);
   const reason=!active?'Sin miembros conectados':!count?'Rescata población en hospitales':!capacity?'Construye un refugio':state.fedUntil<=now?'Falta comida o agua: huerto, pozo o donación al refugio':b.staffed===false?'Puesto pausado manualmente':b.stock>=60?'Reserva llena: pulsa E para recoger':!resource?'Necesita un recurso vivo a menos de 10 m':workers<=0?'Sin trabajador libre: prioriza este puesto':'';
   b.workerReason=reason;b.working=!reason;
   if(!reason){workers--;assigned.set(b.id,resource);}
  }
 }
 return assigned;
}
export function populationView(w,c,now){
 const state=c.workforce||{food:0,water:0,fedUntil:0},jobs=sites(w,c,['sawmill','quarry']);
 return {forecast:supplyForecast(w,c),residents:c.settlers||0,capacity:housing(w,c),food:state.food||0,water:state.water||0,rationCost:Math.ceil((c.settlers||0)/2),fedSeconds:Math.max(0,Math.ceil((state.fedUntil-now)/1000)),working:jobs.filter(b=>b.working).length,people:(w.workers||[]).filter(q=>q.communityId===c.id).map(q=>({id:q.id,name:q.name,x:q.x,y:q.y,status:q.status,order:q.order?.type||'auto',cargo:q.cargo||null})),jobs:jobs.map(b=>({id:b.id,kind:b.kind,x:b.x,y:b.y,working:!!b.working,reason:b.workerReason||'Esperando asignación',stock:b.stock||0}))};
}
