import {addMaterials} from './inventory.mjs';
import {contains} from './structures.mjs';
import {initializeForestScenery} from './forest-scenery.mjs';
import {initializeMountainScenery} from './mountain-scenery.mjs';

export function initializeResources(w){
  if(w.resourceLayout===2){nearbyResources(w);initializeForestScenery(w);initializeMountainScenery(w);return;}
  w.resources??=[];
  w.obstacles??=[];
  for(const c of (w.legacy?[]:w.communities))for(const [i,dx,dy] of [[0,-32,-26],[1,30,25]]){
    const x=c.x+dx,y=c.y+dy,id=`${c.id}-outpost-${i}-ruin`;
    if(x<8||y<8||x>w.size-8||y>w.size-8||w.obstacles.some(o=>o.id===id))continue;
    if(w.adventure?.sites.some(s=>s.interior&&Math.abs(s.x-x)<11&&Math.abs(s.y-y)<9))continue;
    if(w.walls.some(b=>contains(b,x,y,7))||w.resources.some(r=>Math.hypot(r.x-x,r.y-y)<8)||Object.values(w.players).some(p=>Math.hypot(p.x-x,p.y-y)<8))continue;
    w.obstacles.push({id,x,y,sx:4,sy:2});
  }
  for(const c of w.communities)for(let i=0;i<({forest:100,mountain:85,city:35,underground:55}[c.id]||45);i++){
    const angle=i*2.399963,range=21+(i%11)*2.8,x=Math.round((c.x+Math.cos(angle)*range)*5)/5,y=Math.round((c.y+Math.sin(angle)*range)*5)/5;
    if(x<3||y<3||x>w.size-3||y>w.size-3||Math.abs(x-50)<5||(!w.legacy&&(Math.abs(x-160)<5||Math.abs(y-105)<5)))continue;
    if(w.adventure?.sites.some(s=>s.interior&&Math.abs(s.x-x)<7&&Math.abs(s.y-y)<9))continue;
    if((w.obstacles||[]).some(o=>Math.abs(x-o.x)<o.sx+2&&Math.abs(y-o.y)<o.sy+2)||w.walls.some(b=>contains(b,x,y,2)))continue;
    if(w.resources.some(r=>Math.hypot(r.x-x,r.y-y)<2.8))continue;
    const id=`${c.id}-resource-v2-${i}`;
    if(w.resources.some(r=>r.id===id))continue;
    const rock=i%10<({forest:2,mountain:8,city:6,underground:9}[c.id]||5);
    w.resources.push({id,kind:rock?'rock':'tree',x,y,hits:5,maxHits:5,readyAt:0});
  }
  w.resourceLayout=2;
  nearbyResources(w);
  initializeForestScenery(w);
  initializeMountainScenery(w);
}
function nearbyResources(w){
  if(w.nearbyResourcesVersion===1)return;
  w.resources??=[];
  for(const c of w.communities)for(const [i,dx,dy,kind] of [[0,-10,14,'tree'],[1,10,14,'rock'],[2,-14,9,'rock'],[3,14,9,'tree']]){
    const x=c.x+dx,y=c.y+dy,id=`${c.id}-near-resource-${i}`;
    if(w.resources.some(r=>Math.hypot(r.x-x,r.y-y)<3)||w.walls.some(b=>contains(b,x,y,2))||(w.obstacles||[]).some(o=>Math.abs(o.x-x)<o.sx+2&&Math.abs(o.y-y)<o.sy+2)||Object.values(w.players).some(p=>p.alive&&Math.hypot(p.x-x,p.y-y)<2))continue;
    w.resources.push({id,kind,x,y,hits:5,maxHits:5,readyAt:0});
  }
  w.nearbyResourcesVersion=1;
}
export function harvest(w,p,id,now){
  const fail=message=>{p.buildError=message;return false;};
  if(p.equipped!=='tool')return fail('Pulsa Q para equipar el hacha-pico.');
  if(p.reload>0||p.cooldown>0)return fail('Espera a terminar el movimiento anterior.');
  const resource=w.resources?.find(r=>r.id===id);
  if(!resource)return fail('Apunta al tronco de un árbol o a una roca señalados.');
  if(resource.hits<=0)return fail('Este recurso está agotado. Busca otro cercano.');
  const distance=Math.hypot(resource.x-p.x,resource.y-p.y);
  if(distance>3.2)return fail('Acércate a menos de 3,2 m del árbol o la roca.');
  for(let t=.2;t<distance;t+=.2){
    const x=p.x+(resource.x-p.x)*t/distance,y=p.y+(resource.y-p.y)*t/distance;
    if(w.walls.some(b=>!(b.kind==='spikes'||b.kind==='gate'&&b.open)&&contains(b,x,y))||(w.obstacles||[]).some(o=>Math.abs(x-o.x)<o.sx&&Math.abs(y-o.y)<o.sy))return fail('Hay una estructura u obstáculo entre tú y el recurso.');
  }
  const amount=(resource.kind==='tree'?6:8)+(w.communities.find(c=>c.id===p.communityId)?.tech||0);
  addMaterials(p,resource.kind==='tree'?'timber':'stone',amount);p.cooldown=.8;p.toolSwing=(p.toolSwing||0)+1;p.angle=Math.atan2(resource.y-p.y,resource.x-p.x);
  resource.hits--;if(resource.hits===0)resource.readyAt=now+(resource.kind==='tree'?180000:240000);
  p.actionMessage=`${resource.kind==='tree'?'Madera':'Piedra'}: +${amount} materiales${resource.hits===0?' · Recurso agotado':''}`;
  return true;
}
export function resourcesTick(w,now){
  initializeResources(w);
  for(const r of w.resources)if(r.hits<=0&&now>=r.readyAt&&!Object.values(w.players).some(p=>p.alive&&Math.hypot(p.x-r.x,p.y-r.y)<2)&&!w.walls.some(b=>contains(b,r.x,r.y,1.5))&&!w.zombies.some(z=>z.hp>0&&Math.hypot(z.x-r.x,z.y-r.y)<2)&&!(w.workers||[]).some(q=>Math.hypot(q.x-r.x,q.y-r.y)<2)){
    r.hits=r.maxHits;r.readyAt=0;
  }
}
