// Open courtyards: shared server collision and client geometry, with two entrances.
// Existing constructions, resources and agents are never removed during migration.
export function initializeLandmarks(w,a){
  if(a.landmarksVersion===1||w.legacy)return;
  w.obstacles??=[];
  for(const site of a.sites){
    for(const [i,dx,dy,sx,sy] of [[0,-5,0,.5,5],[1,5,0,.5,5],[2,-3,-5,2,.5],[3,3,-5,2,.5],[4,-3,5,2,.5],[5,3,5,2,.5]]){
      const x=site.x+dx,y=site.y+dy,id=site.id+'-courtyard-'+i;
      if(x-sx<3||y-sy<3||x+sx>w.size-3||y+sy>w.size-3)continue;
      if(w.obstacles.some(o=>o.id===id||Math.abs(o.x-x)<o.sx+sx+1&&Math.abs(o.y-y)<o.sy+sy+1))continue;
      if(w.communities.some(c=>Math.hypot(c.x-x,c.y-y)<38))continue;
      if(w.walls.some(b=>Math.abs(b.x-x)<sx+3&&Math.abs(b.y-y)<sy+3))continue;
      if((w.resources||[]).some(r=>Math.abs(r.x-x)<sx+1.5&&Math.abs(r.y-y)<sy+1.5))continue;
      if([...Object.values(w.players),...(w.zombies||[]),...(w.workers||[])].some(p=>Math.abs(p.x-x)<sx+1.5&&Math.abs(p.y-y)<sy+1.5))continue;
      if(w.story?.mages?.some(m=>Math.hypot(m.home.x-x,m.home.y-y)<10)||w.story?.seal&&Math.hypot(w.story.seal.x-x,w.story.seal.y-y)<10)continue;
      w.obstacles.push({id,x,y,sx,sy,landmark:site.kind,height:2.2});
    }
  }
  a.landmarksVersion=1;
}
