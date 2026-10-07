// Authoritative footprints for the illustrated mountain. Existing saves keep their contents.
export function initializeMountainScenery(w){
 if(w.legacy||!w.adventure||w.mountainSceneryVersion===1)return;
 const c=w.communities?.find(c=>c.id==='mountain');if(!c)return;
 const people=[...Object.values(w.players||{}),...(w.workers||[]),...(w.zombies||[])];
 const clear=(x,y,sx,sy,margin=.5)=>
  !w.obstacles.some(o=>o.scenery!=='mountain-water'&&Math.abs(x-o.x)<sx+o.sx+margin&&Math.abs(y-o.y)<sy+o.sy+margin)&&
  !(w.resources||[]).some(r=>Math.abs(x-r.x)<sx+1&&Math.abs(y-r.y)<sy+1)&&
  !(w.walls||[]).some(b=>Math.abs(x-b.x)<sx+2&&Math.abs(y-b.y)<sy+2)&&
  !people.some(p=>Math.abs(x-p.x)<sx+1&&Math.abs(y-p.y)<sy+1);
 const add=(id,x,y,sx,sy,kind)=>w.obstacles.push({id:'mountain-scenery-'+id,x,y,sx,sy,scenery:'mountain-'+kind});
 const free=people.every(p=>Math.hypot(p.x-c.x,p.y-c.y)>4.5)&&
  (w.walls||[]).every(b=>Math.hypot(b.x-c.x,b.y-c.y)>6)&&
  (w.resources||[]).every(r=>Math.hypot(r.x-c.x,r.y-c.y)>4.8);
 c.vault.artScale=free?1.5:1;c.vault.radius=2.2*c.vault.artScale;
 for(const [id,dx,dy,sx,sy,kind] of [
  ['mine',-18,-26,3.5,3.4,'mine'],['radar',21,13,2.0,2.0,'radar'],
  ['store',-8,-5,2.3,2,'hut'],['forge',8,-6,2.3,2,'hut'],
  ['bunker',33,-9,3,2.4,'bunker'],['watch',-33,-30,1.3,1.3,'watch'],
  ['watch-east',39,26,1.3,1.3,'watch']
 ]){
  // Pick a nearby free plot instead of burying a saved building or a campaign entrance.
  for(const [ox,oy] of [[0,0],[0,-5],[5,0],[-5,0],[0,5]]){
   const x=c.x+dx+ox,y=c.y+dy+oy;
   if(Math.abs(x-c.x)<4||Math.abs(y-c.y)<4)continue;
   if((w.adventure.sites||[]).some(s=>Math.hypot(s.x-x,s.y-y)<10))continue;
   if(clear(x,y,sx,sy,.65)){add(id,x,y,sx,sy,kind);break;}
  }
 }
 for(const dx of [-12,12])for(const dy of [-12,12]){
  if(clear(c.x+dx,c.y+dy,1.25,1.25,.2))add(`tower-${dx}-${dy}`,c.x+dx,c.y+dy,1.25,1.25,'tower');
 }
 for(const side of [-1,1])for(const along of [-8.8,-5.4,5.4,8.8])for(const vertical of [false,true]){
  const x=c.x+(vertical?side*12:along),y=c.y+(vertical?along:side*12);
  const sx=vertical?.45:1.6,sy=vertical?1.6:.45;
  if(clear(x,y,sx,sy,.05))add(`wall-${side}-${along}-${vertical}`,x,y,sx,sy,'wall');
 }
 for(const side of [-1,1])for(const dx of [-3.5,3.5]){
  if(clear(c.x+dx,c.y+side*12,.28,.40,0))add(`gatepost-${side}-${dx}`,c.x+dx,c.y+side*12,.28,.40,'gatepost');
 }
 // Deep ravine with two dry, ground-level crossings and a free north/south public road.
 for(let row=0;row<47;row++){
  const y=115+row*2;let start=null;
  const finish=col=>{if(start===null)return;const left=4+start*2,right=4+col*2;add(`river-${row}-${start}`,(left+right)/2,y,(right-left)/2,1,'water');start=null;};
  for(let col=0;col<=47;col++){
   const x=5+col*2,channel=23+Math.sin((y-110)*.08)*5;
   const wet=col<47&&Math.abs(x-channel)<4&&Math.abs(y-160)>3&&Math.abs(y-188)>3&&Math.abs(x-50)>3&&clear(x,y,1,1,.8);
   if(wet&&start===null)start=col;if(!wet)finish(col);
  }
 }
 for(let row=0;row<26;row++)for(let col=0;col<26;col++){
  const x=5+col*3.5+Math.sin(row*19+col*7),y=115+row*3.5+Math.cos(col*13+row*5);
  if(Math.hypot(x-c.x,y-c.y)<19||Math.abs(x-50)<5||Math.abs(y-160)<4||Math.abs(y-188)<3)continue;
  if(Math.abs(x-(23+Math.sin((y-110)*.08)*5))<6)continue;
  if((w.adventure.sites||[]).some(s=>Math.hypot(s.x-x,s.y-y)<10))continue;
  const peak=(row<6||col<3||col>22)&&((row+col)%3===0);
  const half=peak?1.25:.3;
  if(clear(x,y,half,half,peak?1.0:2.5))add(`${peak?'cliff':'pine'}-${row}-${col}`,x,y,half,half,peak?'cliff':'pine');
 }
 w.mountainSceneryVersion=1;
}
