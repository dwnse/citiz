import {isSolid,contains} from './structures.mjs';
// Routes are transient: never serialized into saves or sent to clients.
import {vaults} from './communities.mjs';
const runtime = new WeakMap();
export function solid(world, x, y, radius = .6, walls = true) {
  return x < 2 || y < 2 || x > (world.size||100)-2 || y > (world.size||100)-2 ||
    vaults(world).some(v=>Math.hypot(x-v.x, y-v.y) < 2.2+radius) ||
    (world.obstacles || []).some(b => Math.abs(b.x-x) < b.sx+radius && Math.abs(b.y-y) < b.sy+radius) ||
    (walls && world.walls.some(b => isSolid(b) && contains(b,x,y,radius)));
}

function clearSegment(world, a, b) {
  const length = Math.hypot(b.x-a.x,b.y-a.y), steps = Math.max(1,Math.ceil(length/.3));
  for(let i=1;i<=steps;i++) if(solid(world,a.x+(b.x-a.x)*i/steps,a.y+(b.y-a.y)*i/steps)) return false;
  return true;
}

export function findPath(world, start, target, reach = 2.3, limit = 2400) {
  const candidates=[];
  for(let dx=-1;dx<=1;dx++)for(let dy=-1;dy<=1;dy++)candidates.push({x:Math.round(start.x)+dx,y:Math.round(start.y)+dy});
  candidates.sort((a,b)=>Math.hypot(a.x-start.x,a.y-start.y)-Math.hypot(b.x-start.x,b.y-start.y));
  const origin=candidates.find(p=>!solid(world,p.x,p.y)&&clearSegment(world,start,p));
  if(!origin)return [];
  const key = p => p.x+','+p.y;
  const heuristic = p => Math.max(0, Math.hypot(p.x-target.x,p.y-target.y)-reach);
  const open = [{...origin,g:0,f:heuristic(origin)}], best = new Map([[key(origin),0]]), parents = new Map();
  let expanded=0;
  while(open.length && expanded++<limit) {
    let min=0;for(let i=1;i<open.length;i++)if(open[i].f<open[min].f)min=i;
    const current=open.splice(min,1)[0];
    if(current.g!==best.get(key(current)))continue;
    if(heuristic(current)===0) {
      const path=[{x:current.x,y:current.y}];let k=key(current);
      while(parents.has(k)){const prev=parents.get(k);path.push(prev);k=key(prev);}
      return path.reverse();
    }
    for(const [dx,dy] of [[1,0],[-1,0],[0,1],[0,-1]]) {
      const next={x:current.x+dx,y:current.y+dy},g=current.g+1,k=key(next);
      if(solid(world,next.x,next.y) || g >= (best.get(k)??Infinity))continue;
      best.set(k,g);parents.set(k,{x:current.x,y:current.y});open.push({...next,g,f:g+heuristic(next)});
    }
  }
  return [];
}

export function beginNavigation(world, dt) {
  let nav=runtime.get(world);
  if(!nav){nav={clock:0,budget:0,cursor:0,allowed:new Set(),routes:new Map(),searches:0};runtime.set(world,nav);}
  nav.clock+=dt;nav.budget=2;
  // Rotate eligibility so early entities cannot consume every search slot.
  nav.allowed.clear();
  for(let i=0;i<Math.min(2,world.zombies.length);i++)nav.allowed.add(world.zombies[(nav.cursor+i)%world.zombies.length].id);
  nav.cursor=(nav.cursor+2)%Math.max(1,world.zombies.length);
  const ids=new Set(world.zombies.map(z=>z.id));for(const id of nav.routes.keys())if(!ids.has(id))nav.routes.delete(id);
}

export function direction(world, zombie, target, reach) {
  const nav=runtime.get(world);
  let route=nav.routes.get(zombie.id);
  if((!route || nav.clock>=route.expires || Math.hypot(route.target.x-target.x,route.target.y-target.y)>3) && nav.budget>0 && nav.allowed.has(zombie.id)) {
    nav.budget--;nav.searches++;
    route={path:findPath(world,zombie,target,reach),expires:nav.clock+1.5,target:{x:target.x,y:target.y}};
    nav.routes.set(zombie.id,route);
  }
  while(route?.path.length && Math.hypot(route.path[0].x-zombie.x,route.path[0].y-zombie.y)<.25)route.path.shift();
  const waypoint=route?.path[0];
  if(waypoint && clearSegment(world,zombie,waypoint))return {angle:Math.atan2(waypoint.y-zombie.y,waypoint.x-zombie.x),routed:true};
  return {angle:Math.atan2(target.y-zombie.y,target.x-zombie.x),routed:false};
}
export function navigationMetrics(world){const n=runtime.get(world);return {searches:n?.searches||0,cachedRoutes:n?.routes.size||0};}
