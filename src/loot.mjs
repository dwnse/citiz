import {addMaterials} from './inventory.mjs';
import {randomUUID} from 'node:crypto';
export function zombieLoot(w,z,killerCommunity=null,now=Date.now()){
  if(z.lootDropped)return;
  z.lootDropped=true;
  if(z.finalBoss){
    if(w.story?.patient){w.story.patient.defeated=true;w.story.patient.defeatedBy=killerCommunity;}
    w.drops.push({id:randomUUID(),x:z.x,y:z.y,wood:0,ammo:24,sample:true});return;
  }
  if(!z.boss&&!z.reanimated){w.fallen??=[];w.fallen.push({id:z.id,x:z.x,y:z.y,maxHp:z.maxHp||68,level:z.level||1,variant:z.variant||'walker',diedAt:now});w.fallen=w.fallen.slice(-64);}
  const roll=[...String(z.id)].reduce((n,c)=>n+c.charCodeAt(0),0)%4;
  w.drops.push({id:randomUUID(),x:z.x,y:z.y,wood:0,ammo:roll<2?12:6,food:roll===2?2:0,water:roll===3?2:0,medical:roll===1?1:0});
}
export function collectLoot(w,p,d){
  if(d.materials){for(const [key,n] of Object.entries(d.materials))addMaterials(p,key,n);}else addMaterials(p,'reclaimed',d.wood||0);p.reserve+=d.ammo||0;
  for(const key of ['food','water','medical'])p[key]=(p[key]||0)+(d[key]||0);
  if(d.sample)p.sample=true;
  p.actionMessage=`Recogido: ${d.ammo||0} balas, ${d.food||0} comida, ${d.water||0} agua, ${d.medical||0} botiquines${d.wood?' y '+d.wood+' materiales':''}`;
  if(d.sample)p.actionMessage='Muestra del origen recuperada. Llévala a un Laboratorio del Sello: requiere 6 claves y 3 informes.';
  w.drops=w.drops.filter(q=>q!==d);return true;
}

export function damageInfected(w,z,damage,now,killerCommunity){
 if(z.hp<=0)return false;
 z.hp=Math.max(0,z.hp-damage);
 if(z.boss&&!z.finalBoss&&z.warning>0){
  z.castDamage=(z.castDamage||0)+damage;
  if(z.castDamage>=(z.interruptThreshold||80)){z.warning=0;z.ability=6;z.interruptedUntil=now+1500;}
 }
 if(z.hp===0){zombieLoot(w,z,killerCommunity,now);return true;}
 return false;
}
