import {core,protectedRoad} from './communities.mjs';
import {randomUUID} from 'node:crypto';

export const STRUCTURES = Object.freeze({
  wall:{name:'Muro',cost:20,hp:180,width:3.2,depth:1.2,height:2.4,description:'Defensa modular. Encaja por sus extremos.'},
  gate:{name:'Portón',cost:30,hp:240,width:3.2,depth:1.2,height:2.4,description:'E abre/cierra. Abierto deja pasar agentes, zombis y disparos.'},
  spikes:{name:'Pinchos',cost:15,hp:90,width:3.2,depth:1.2,height:.6,description:'Transitables. Dañan infectados y se desgastan.'},
  workshop:{name:'Taller',cost:60,hp:300,width:3.2,depth:3.2,height:1.5,description:'E: 30 balas por 15 materiales. C cerca obtiene la misma mejora.'},
  infirmary:{name:'Enfermería',cost:50,hp:260,width:3.2,depth:3.2,height:1.7,description:'E: recupera 35 PV por 10 materiales.'},
  well:{name:'Pozo',cost:40,hp:300,width:3.2,depth:3.2,height:1.5,description:'Produce agua cada 30 s, hasta 5 usos. E: +40 hidratación.'},
  garden:{name:'Huerto',cost:45,hp:160,width:3.2,depth:3.2,height:.4,description:'Produce comida cada 60 s, hasta 5 usos. E: +35 alimento.'},
  storage:{name:'Almacén',cost:35,hp:280,width:3.2,depth:3.2,height:1.5,description:'T: guarda 20 materiales. E: retira hasta 20. Compartido con aliados.'}
});
export const catalog = () => Object.entries(STRUCTURES).map(([id,s])=>({id,...s}));
export const definition = b => Object.hasOwn(STRUCTURES,b.kind||'wall')?STRUCTURES[b.kind||'wall']:STRUCTURES.wall;
export function bounds(b){const d=definition(b);return b.rot===1?{x:d.depth/2,y:d.width/2}:{x:d.width/2,y:d.depth/2};}
export const isSolid = b => !(b.kind==='spikes'||b.kind==='gate'&&b.open);
export function contains(b,x,y,r=0){const h=bounds(b);return Math.abs(b.x-x)<h.x+r&&Math.abs(b.y-y)<h.y+r;}
export const quantize = n => Math.round(n*5)/5;

// The client sends endpoints; the authority derives and validates every piece.
export function buildRow(w,p,msg,now){
  if(!['wall','gate','spikes'].includes(msg.kind)||![msg.x,msg.y,msg.endX,msg.endY].every(Number.isFinite))return false;
  const x=quantize(msg.x),y=quantize(msg.y),dx=msg.endX-x,dy=msg.endY-y;
  const vertical=Math.abs(dy)>Math.abs(dx),steps=Math.round(Math.abs(vertical?dy:dx)/3.2);
  if(steps>19)return false;
  const direction=Math.sign(vertical?dy:dx)||1,rot=vertical?1:0,planned=[],d=STRUCTURES[msg.kind];
  const shadow={...w,walls:[...w.walls]},payer={...p};
  for(let i=0;i<=steps;i++){
    const point={x:quantize(x+(vertical?0:i*3.2*direction)),y:quantize(y+(vertical?i*3.2*direction:0))};
    const reason=placementReason(shadow,payer,point.x,point.y,msg.kind,rot,true);
    if(reason){p.buildError=reason;return false;}
    const b={id:randomUUID(),communityId:p.communityId,kind:msg.kind,...point,rot,hp:d.hp,maxHp:d.hp,open:false,stock:0,producedAt:now};
    planned.push(b);shadow.walls.push(b);payer.wood-=d.cost;
  }
  p.wood=payer.wood;p.buildError='';w.walls.push(...planned);return true;
}

export function upgradeStructure(w,p,b){
  if(!b||b.communityId!==p.communityId||b.hp<=0||Math.hypot(p.x-b.x,p.y-b.y)>5)return false;
  const level=b.level||0,cost=Math.ceil(definition(b).cost*(level+1));
  if(level>=2||p.wood<cost)return false;
  p.wood-=cost;b.level=level+1;const bonus=Math.ceil(definition(b).hp*.5);
  b.maxHp=(b.maxHp||definition(b).hp)+bonus;b.hp+=bonus;return true;
}

export function placementReason(w,p,x,y,kind='wall',rot=0,remote=false){
  const d=typeof kind==='string'&&Object.hasOwn(STRUCTURES,kind)?STRUCTURES[kind]:null;if(!d||!Number.isFinite(x)||!Number.isFinite(y))return 'Plano inválido';
  const v=core(w,p),radius=18+(v.upgrades||0)*6,b={x,y,kind,rot},h=bounds(b),distance=Math.hypot(x-v.x,y-v.y);
  if(!p.alive||w.phase!=='active'||v.hp<=0)return 'No puedes construir ahora';
  if(p.wood<d.cost)return 'Materiales insuficientes';
  if(w.walls.filter(b=>(b.communityId||'forest')===p.communityId).length>=80)return 'Límite de 80 estructuras';
  if(distance>=radius||distance<=4)return 'Fuera del territorio de construcción';
  if(remote?Math.hypot(p.x-v.x,p.y-v.y)>radius+6:Math.hypot(p.x-x,p.y-y)>=9)return 'Acércate a tu base';
  if(x-h.x<2||y-h.y<2||x+h.x>w.size-2||y+h.y>w.size-2)return 'Fuera del mapa';
  if(protectedRoad(w,x,y))return 'Corredor público reservado';
  if(w.story&&(Math.hypot(x-w.story.seal.x,y-w.story.seal.y)<7||w.story.mages.some(m=>Math.abs(x-m.home.x)<3&&Math.abs(y-m.home.y)<9)))return 'Zona de historia reservada';
  if((w.obstacles||[]).some(o=>Math.abs(o.x-x)<o.sx+h.x&&Math.abs(o.y-y)<o.sy+h.y))return 'Obstáculo en el terreno';
  if(w.walls.some(o=>{const a=bounds(o);return Math.abs(o.x-x)<a.x+h.x-.001&&Math.abs(o.y-y)<a.y+h.y-.001;}))return 'Se solapa con otra estructura';
  if(Object.values(w.players).some(q=>q.alive&&contains(b,q.x,q.y,.65))||w.zombies.some(z=>z.hp>0&&contains(b,z.x,z.y,.65)))return 'Hay alguien en el plano';
  return '';
}

export function useStructure(w,p,b,now){
  if(!b||b.hp<=0||b.communityId!==p.communityId||Math.hypot(p.x-b.x,p.y-b.y)>4.5)return false;
  switch(b.kind){
    case 'gate':
      if((b.toggleAfter||0)>now)return false;
      if(b.open&&([...Object.values(w.players).filter(q=>q.alive),...w.zombies].some(q=>contains(b,q.x,q.y,.65))))return false;
      b.open=!b.open;b.toggleAfter=now+300;return true;
    case 'workshop': if(p.wood<15)return false;p.wood-=15;p.reserve+=30+(b.level||0)*6;return true;
    case 'infirmary': if(p.wood<10||p.hp>=100)return false;p.wood-=10;p.hp=Math.min(100,p.hp+35+(b.level||0)*10);return true;
    case 'well': if((b.stock||0)<1||p.thirst>=100)return false;b.stock--;p.thirst=Math.min(100,p.thirst+40);return true;
    case 'garden': if((b.stock||0)<1||p.hunger>=100)return false;b.stock--;p.hunger=Math.min(100,p.hunger+35);return true;
    case 'storage': {const n=Math.min(20,b.stock||0);if(!n)return false;b.stock-=n;p.wood+=n;return true;}
  }return false;
}

export function structuresTick(w,dt,now){
  for(const b of w.walls){
    const interval=(b.kind==='well'?30000:b.kind==='garden'?60000:0)/(1+(b.level||0)*.25);
    if(interval){b.producedAt??=now;const count=Math.floor((now-b.producedAt)/interval);if(count>0){b.stock=Math.min(5,(b.stock||0)+count);b.producedAt+=count*interval;}}
    if(b.kind==='spikes'&&(b.attackAfter||0)<=now){
      const targets=w.zombies.filter(z=>z.hp>0&&contains(b,z.x,z.y,.5));
      if(targets.length){for(const z of targets){z.hp=Math.max(0,z.hp-18);if(z.hp===0)w.drops.push({id:randomUUID(),x:z.x,y:z.y,wood:8,ammo:6});}b.hp=Math.max(0,b.hp-5);b.attackAfter=now+1000;}
    }
  }
}
