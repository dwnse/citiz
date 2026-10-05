import {randomUUID} from 'node:crypto';
import {solid} from './navigation.mjs';
export const RALLY={duration:8000,speed:1.35,damage:1.3};
export const BOSS_TYPES={
 healer:{name:'El Cantor',abilityName:'Curación',hp:420,radius:9,warning:2.5,cooldown:12,tint:'#79d6a0'},
 reviver:{name:'El Sepulturero',abilityName:'Resurrección',hp:480,radius:10,warning:3,cooldown:16,tint:'#ba91ed'},
 rally:{name:'El Heraldo',abilityName:'Frenesí',hp:500,radius:10,warning:2.5,cooldown:14,tint:'#eeb568'},
 bulwark:{name:'El Portador',abilityName:'Descarga',hp:650,radius:6,warning:2,cooldown:10,tint:'#ec7769'}
};
export function bossFields(type){const d=BOSS_TYPES[type]||BOSS_TYPES.bulwark;return {boss:true,bossType:type,bossName:d.name,abilityName:d.abilityName,abilityRadius:d.radius,abilityTint:d.tint,hp:d.hp,maxHp:d.hp,ability:8,warning:0,interruptThreshold:80};}
export function pruneFallen(w,now){w.fallen=(w.fallen||[]).filter(z=>now-z.diedAt<60000).slice(-64);}
export function bossTick(w,z,players,dt,now,hurt){
 const d=BOSS_TYPES[z.bossType]||BOSS_TYPES.bulwark;
 z.abilityRadius=d.radius;z.abilityName=d.abilityName;z.abilityTint=d.tint;z.bossName=d.name;
 if(z.warning>0){
  z.warning=Math.max(0,z.warning-dt);if(z.warning>0)return;
  const nearby=w.zombies.filter(q=>q!==z&&q.hp>0&&!(q.charmUntil>now)&&Math.hypot(q.x-z.x,q.y-z.y)<=d.radius);
  if(z.bossType==='healer')for(const q of nearby)q.hp=Math.min(q.maxHp||q.hp,q.hp+35);
  else if(z.bossType==='rally')for(const q of nearby)q.rallyUntil=now+RALLY.duration;
  else if(z.bossType==='reviver'){
   let count=0;
   for(const corpse of w.fallen||[]){
    if(count>=2||w.zombies.filter(q=>q.hp>0).length>=96)break;
    if(corpse.raised||now-corpse.diedAt>=60000||Math.hypot(corpse.x-z.x,corpse.y-z.y)>d.radius||solid(w,corpse.x,corpse.y)||w.zombies.some(q=>q.hp>0&&Math.hypot(q.x-corpse.x,q.y-corpse.y)<1)||players.some(p=>p.alive&&Math.hypot(p.x-corpse.x,p.y-corpse.y)<1))continue;
    corpse.raised=true;count++;
    w.zombies.push({id:randomUUID(),x:corpse.x,y:corpse.y,hp:Math.ceil(corpse.maxHp/2),maxHp:corpse.maxHp,level:corpse.level,variant:corpse.variant,communityId:z.communityId,boss:false,attack:1,reanimated:true,lootDropped:true});
   }
  }else for(const p of players)if(p.alive&&Math.hypot(p.x-z.x,p.y-z.y)<d.radius)hurt(w,p,35,now);
  z.ability=d.cooldown;z.castDamage=0;return;
 }
 z.ability=Math.max(0,(z.ability??8)-dt);
 if(z.ability===0){z.warning=d.warning;z.castDamage=0;}
}
