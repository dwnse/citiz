import {findPath,solid} from './navigation.mjs';
import {contains,isSolid} from './structures.mjs';
import {workerSeconds,workerYield} from './balance.mjs';

const runtime=new WeakMap();
const distance=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
const names=['Inés','Bruno','Alma','Darío','Luz','Tomás','Vera','Simón'];
export function workerOrder(w,p,msg){
  const fail=message=>{p.buildError=message;return false;};
  const npc=(w.workers||[]).find(q=>q.id===msg.id),c=w.communities.find(q=>q.id===p.communityId);
  if(!npc||npc.communityId!==p.communityId)return fail('Selecciona un residente de tu comunidad.');
  if(distance(p,c.vault)>24+(c.vault.upgrades||0)*6)return fail('Vuelve a tu base para dar órdenes a los residentes.');
  if(!['move','hold','return','auto'].includes(msg.order))return fail('Orden de residente desconocida.');
  if(msg.order==='move'&&(!Number.isFinite(msg.x)||!Number.isFinite(msg.y)||distance(msg,c.vault)>40+(c.vault.upgrades||0)*6||solid(w,msg.x,msg.y)))return fail('Elige suelo libre a menos de 40 m de tu bóveda (más su ampliación).');
  npc.order=msg.order==='auto'?null:{type:msg.order,...(msg.order==='move'?{x:msg.x,y:msg.y}:{})};
  npc.work=0;
  if(!npc.cargo)npc.jobId=null;
  runtime.get(w)?.routes.delete(npc.id);
  p.actionMessage={move:'Destino indicado: al llegar permanecerá allí',hold:'Residente detenido; conserva la carga',return:'Regresará al refugio y esperará',auto:'Residente disponible para los puestos'}[msg.order];
  return true;
}

function stepAside(w,npc,angle,step){
  const nearby=w.workers.filter(q=>q!==npc&&distance(q,npc)<1.5);
  for(const offset of [0,.65,-.65,1.25,-1.25]){
    const point={x:npc.x+Math.cos(angle+offset)*step,y:npc.y+Math.sin(angle+offset)*step};
    if(solid(w,point.x,point.y)||!clear(w,npc,point))continue;
    if(nearby.some(q=>distance(q,point)<.85&&distance(q,point)<distance(q,npc)+.001))continue;
    npc.x=point.x;npc.y=point.y;npc.angle=angle+offset;return true;
  }
  npc.status='Esperando paso: otro residente';return false;
}
function freePoint(w,home){
  for(let radius=3;radius<=9;radius++)for(let i=0;i<16;i++){
    const p={x:home.x+Math.cos(i*Math.PI/8)*radius,y:home.y+Math.sin(i*Math.PI/8)*radius};
    if(!solid(w,p.x,p.y)&&!(w.workers||[]).some(q=>distance(q,p)<1))return p;
  }
  return null;
}
function clear(w,a,b){
  const n=Math.ceil(distance(a,b)/.25);
  for(let i=1;i<=n;i++)if(solid(w,a.x+(b.x-a.x)*i/n,a.y+(b.y-a.y)*i/n))return false;
  return true;
}
function interactionClear(w,a,target){
  const length=distance(a,target),steps=Math.ceil(length/.3);
  for(let i=1;i<=steps;i++){
    const x=a.x+(target.x-a.x)*i/steps,y=a.y+(target.y-a.y)*i/steps;
    if(w.walls.some(b=>b.id!==target.id&&b.hp>0&&isSolid(b)&&contains(b,x,y))||
       (w.obstacles||[]).some(o=>Math.abs(o.x-x)<o.sx&&Math.abs(o.y-y)<o.sy)||
       (w.resources||[]).some(r=>r.id!==target.id&&r.hits>0&&Math.hypot(r.x-x,r.y-y)<(r.kind==='tree'?.4:.8)))return false;
  }
  return true;
}
function walk(w,npc,target,reach,dt,nav){
  if(distance(npc,target)<=reach&&interactionClear(w,npc,target))return true;
  let route=nav.routes.get(npc.id);
  if(route&&distance(route.target,target)>1){nav.routes.delete(npc.id);route=null;}
  const d=distance(npc,target),direct={x:target.x+(npc.x-target.x)*reach/d,y:target.y+(npc.y-target.y)*reach/d};
  let next=d>reach&&clear(w,npc,direct)&&interactionClear(w,direct,target)?direct:null;
  if(!next){
    if((!route||route.until<=nav.time||distance(route.target,target)>1)&&nav.allowed===npc.id){
      route={path:findPath(w,npc,target,reach,800,point=>interactionClear(w,point,target)),target:{...target},until:nav.time+2};nav.routes.set(npc.id,route);
    }
    while(route?.path.length&&distance(npc,route.path[0])<.2)route.path.shift();
    // A nearby waypoint is only a guide; do not queue at a grid cell occupied by a peer.
    while(route?.path.length>1&&distance(npc,route.path[0])<1.2&&clear(w,npc,route.path[1]))route.path.shift();
    next=route?.path[0];
    if(!next||!clear(w,npc,next)){if(next)nav.routes.delete(npc.id);npc.status='Paso bloqueado: abre un portón';return false;}
  }
  const step=Math.min(distance(npc,next),2.8*Math.min(dt,.1)),angle=Math.atan2(next.y-npc.y,next.x-npc.x);
  stepAside(w,npc,angle,step);
  return distance(npc,target)<=reach+.02&&interactionClear(w,npc,target);
}

// Positions and cargo persist; paths are transient and at most one A* search runs per tick.
export function workersTick(w,assigned,online,dt,now){
  w.workers??=[];
  let nav=runtime.get(w);
  if(!nav){nav={routes:new Map(),time:0,cursor:0};runtime.set(w,nav);}
  nav.time+=dt;
  const keep=new Set(),taken=new Set();
  for(const c of w.communities){
    const homes=w.walls.filter(b=>b.kind==='shelter'&&b.hp>0&&b.communityId===c.id);
    const count=Math.min(c.settlers||0,160);
    for(let i=0;i<count;i++){
      const id=`resident-${c.id}-${i}`;keep.add(id);
      if(!w.workers.some(q=>q.id===id)){
        const point=freePoint(w,homes[Math.floor(i/2)]||c);
        if(point)w.workers.push({id,communityId:c.id,name:names[i%names.length]+' '+(1+Math.floor(i/names.length)),...point,angle:0,work:0,status:'En el refugio'});
      }
    }
  }
  w.workers=w.workers.filter(q=>keep.has(q.id));
  for(const id of nav.routes.keys())if(!keep.has(id))nav.routes.delete(id);
  nav.allowed=w.workers[nav.cursor++%Math.max(1,w.workers.length)]?.id;
  // Preserve existing assignments so changing priorities does not exchange workers every tick.
  for(const npc of w.workers)if(npc.jobId&&(npc.cargo||assigned.has(npc.jobId)))taken.add(npc.jobId);
  for(const npc of w.workers){
    const c=w.communities.find(c=>c.id===npc.communityId);
    const active=!online||Object.values(w.players).some(p=>p.alive&&p.communityId===c.id&&online.has(p.id));
    if(!active){npc.status='Comunidad desconectada';continue;}
    const homes=w.walls.filter(b=>b.kind==='shelter'&&b.hp>0&&b.communityId===c.id),home=homes[0]||c;
    let job=w.walls.find(b=>b.id===npc.jobId&&b.hp>0);
    if(npc.cargo&&!job){
      w.drops.push({id:'cargo-'+npc.id+'-'+now,x:npc.x,y:npc.y,wood:npc.cargo.amount,materials:{[npc.cargo.kind]:npc.cargo.amount},ammo:0});npc.cargo=null;
    }
    if(!npc.order&&!npc.cargo&&(!job||!assigned.has(job.id))){
      const previous=npc.jobId;npc.jobId=null;npc.work=0;
      job=w.walls.find(b=>b.communityId===c.id&&assigned.has(b.id)&&!taken.has(b.id));
      if(job){npc.jobId=job.id;taken.add(job.id);}
      if(previous!==npc.jobId)nav.routes.delete(npc.id);
    }
    const threatened=w.zombies.some(z=>z.hp>0&&!(z.charmUntil>now)&&distance(z,npc)<7);
    if(npc.order&&!threatened){
      if(npc.order.type==='hold'){npc.status='Esperando órdenes';continue;}
      const target=npc.order.type==='return'?home:npc.order;
      npc.status=npc.order.type==='return'?'Regresando por orden':'Moviéndose por orden';
      if(walk(w,npc,target,npc.order.type==='return'?3:.65,dt,nav)){
        npc.order={type:'hold'};npc.status='En destino: esperando órdenes';nav.routes.delete(npc.id);
      }
      continue;
    }
    if(threatened||!job){npc.status=threatened?'En peligro: buscando refugio':'Regresando al refugio';if(walk(w,npc,home,3,dt,nav))npc.status=threatened?'Refugiado: despeja los infectados':'En el refugio';if(job)job.workerReason=npc.status;continue;}
    if(npc.cargo){
      npc.status='Transportando '+npc.cargo.amount+' materiales';
      if(walk(w,npc,job,3.2,dt,nav)){
        const delivered=Math.min(npc.cargo.amount,60-(job.stock||0));job.stock=(job.stock||0)+delivered;npc.cargo.amount-=delivered;
        if(!npc.cargo.amount){npc.cargo=null;npc.work=0;nav.routes.delete(npc.id);}else npc.status='Almacén lleno: recoge la producción';
      }
    }else{
      const resource=assigned.get(job.id);
      npc.status='Caminando al recurso';
      if(resource?.hits>0&&walk(w,npc,resource,1.8,dt,nav)){
        npc.status='Extrayendo';npc.work+=dt;npc.angle=Math.atan2(resource.y-npc.y,resource.x-npc.x);
        if(npc.work>=workerSeconds(job.level)){resource.hits--;if(!resource.hits)resource.readyAt=now+(resource.kind==='tree'?180000:240000);npc.cargo={kind:resource.kind==='tree'?'timber':'stone',amount:workerYield(resource.kind,c.tech)};npc.work=0;nav.routes.delete(npc.id);}
      }
    }
    job.workerReason=npc.status;job.producedAt=now-Math.min(workerSeconds(job.level),npc.work)*1000;
  }
}
