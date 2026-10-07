// The illustrated forest is shared scenery, not extra harvestable resources.
export function initializeForestScenery(w) {
  if(w.legacy||!w.adventure||!w.communities?.some(c=>c.id==='forest')||w.forestSceneryVersion===2)return;
  w.obstacles=(w.obstacles||[]).filter(o=>!o.scenery?.startsWith('forest-'));
  const c=w.communities.find(c=>c.id==='forest');
  const people=[...Object.values(w.players||{}),...(w.workers||[]),...(w.zombies||[])];
  const clear=(x,y,sx,sy,margin=.5)=>
    !w.obstacles.some(o=>!['forest-fence','forest-water'].includes(o.scenery)&&Math.abs(x-o.x)<sx+o.sx+margin&&Math.abs(y-o.y)<sy+o.sy+margin)&&
    !(w.resources||[]).some(r=>Math.abs(x-r.x)<sx+.9&&Math.abs(y-r.y)<sy+.9)&&
    !(w.walls||[]).some(b=>Math.abs(x-b.x)<sx+2.0&&Math.abs(y-b.y)<sy+2.0)&&
    !people.some(p=>Math.abs(x-p.x)<sx+1&&Math.abs(y-p.y)<sy+1);
  const coreFree=people.every(p=>Math.hypot(p.x-c.x,p.y-c.y)>4.3)&&
    (w.walls||[]).every(b=>Math.hypot(b.x-c.x,b.y-c.y)>6.0)&&
    (w.resources||[]).every(r=>Math.hypot(r.x-c.x,r.y-c.y)>4.7);
  c.vault.artScale=coreFree?1.65:1.0;
  c.vault.radius=2.2*c.vault.artScale;
  const add=(id,x,y,sx,sy,scenery)=>w.obstacles.push({id:'forest-scenery-'+id,x,y,sx,sy,scenery});
  // Fixed models from the reference: no production, stock, cost or catalogue entries.
  for(const [id,dx,dy,sx,sy,scenery] of [
    ['workshop',-10,-6,2.1,2.0,'forest-workshop'],
    ['garden',9,6,2.7,2.1,'forest-garden'],
    ['tank',11,-10,1.0,1.0,'forest-tank'],
    ['tent',21,3,2.2,1.8,'forest-tent'],
    ['lumber-hut',-22,-9,2.7,2.0,'forest-workshop'],
    ['watermill',-34,12,2.1,1.8,'forest-watermill'],
    ['east-cave',42,26,3.0,3.0,'forest-cave'],
    ['north-cave',42,-29,3.0,3.0,'forest-mine']
  ]){
    const x=c.x+dx,y=c.y+dy;
    if(clear(x,y,sx,sy,.8))add(id,x,y,sx,sy,scenery);
  }
  for(const side of [-1,1])for(let i=-4;i<=4;i++){
    if(Math.abs(i)<2)continue;
    for(const vertical of [false,true]){
      const x=c.x+(vertical?side*16:i*3.2),y=c.y+(vertical?i*3.2:side*16);
      const sx=vertical?.3:1.6,sy=vertical?1.6:.3;
      if(clear(x,y,sx,sy,.25))add(`fence-${side}-${i}-${vertical}`,x,y,sx,sy,'forest-fence');
    }
  }
  for(const dx of [-16,16])for(const dy of [-16,16]){
    const x=c.x+dx,y=c.y+dy;
    if(clear(x,y,1.0,1.0,.1))add(`tower-${dx}-${dy}`,x,y,1.0,1.0,'forest-tower');
  }
  // The same river rectangles drive the floor cutout, cliffs, movement and construction.
  for(let row=0;row<47;row++){
    const y=5+row*2;
    let start=null;
    const finish=col=>{if(start===null)return;const left=4+start*2,right=4+col*2;add(`water-${row}-${start}`,(left+right)/2,y,(right-left)/2,1,'forest-water');start=null;};
    for(let col=0;col<=47;col++){
      const x=5+col*2;
      const stream=Math.min(Math.abs(x-(10.5+Math.cos(y*.095)*2.5)),x<72?Math.abs(y-(84+Math.sin(x*.07)*4)):100);
      const wet=col<47&&stream<3.8&&Math.abs(x-50)>2.45&&Math.abs(y-50)>2.45&&clear(x,y,1,1,.6);
      if(wet&&start===null)start=col;
      if(!wet)finish(col);
    }
  }
  for(let row=0;row<26;row++)for(let col=0;col<26;col++){
    const x=5+col*3.5+Math.sin(row*31+col*7)*1.15,y=5+row*3.5+Math.cos(col*17+row*3)*1.15;
    if(Math.hypot(x-c.x,y-c.y)<22||Math.abs(x-50)<5||Math.abs(y-50)<5)continue;
    if(Math.abs(x-(10.5+Math.cos(y*.095)*2.5))<6||Math.abs(y-(84+Math.sin(x*.07)*4))<6)continue;
    if(!clear(x,y,.3,.3,2.5))continue;
    if((w.resources||[]).some(r=>Math.hypot(x-r.x,y-r.y)<3.2))continue;
    if((w.adventure.sites||[]).some(s=>Math.hypot(x-s.x,y-s.y)<10))continue;
    add(`tree-${row}-${col}`,x,y,.3,.3,'forest-tree');
  }
  w.forestSceneryVersion=2;
}
