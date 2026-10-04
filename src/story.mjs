import {core} from './communities.mjs';
import {solid} from './navigation.mjs';

export const SPELLS = [
  {id:'heal',name:'Alivio',key:'2',cost:20,cooldown:12000,duration:0,description:'Recupera 25 de salud.'},
  {id:'haste',name:'Ímpetu',key:'3',cost:25,cooldown:18000,duration:6000,description:'Velocidad ×1,6 durante 6 segundos.'},
  {id:'fury',name:'Fulgor',key:'4',cost:30,cooldown:22000,duration:8000,description:'Daño de pistola ×1,4 durante 8 segundos.'},
  {id:'resist',name:'Temple',key:'5',cost:25,cooldown:20000,duration:8000,description:'Reduce el daño recibido un 40 % durante 8 segundos.'},
  {id:'control',name:'Vínculo',key:'6',cost:40,cooldown:30000,duration:8000,description:'Hasta 3 infectados cercanos combaten a la horda durante 8 segundos. No afecta jefes.'},
  {id:'shield',name:'Amparo',key:'7',cost:35,cooldown:24000,duration:6000,description:'Absorbe hasta 40 de daño durante 6 segundos.'}
];
const CHAPTERS = [
  {name:'Alda',text:'Humanos y magos trabajábamos juntos. La vacuna debía reparar tejidos; la magia le enseñó a reescribirlos.'},
  {name:'Iriel',text:'El Paciente 0 no recibió una dosis normal. Seis patrones de energía alteraron su ADN de forma irreversible.'},
  {name:'Marek',text:'La muerte no lo detuvo. Su campo mata a quienes se acercan y vuelve a levantar sus cuerpos como infectados.'},
  {name:'Nerea',text:'Los seis sellamos al Paciente 0, pero el sello solo retiene su cuerpo. La horda siguió creciendo dentro de la ciudad.'},
  {name:'Orin',text:'La cura necesita una muestra viva del origen y los seis patrones invertidos. Quemar la ciudad destruiría también la cura.'},
  {name:'Selka',text:'El sello cederá al cumplirse treinta días. Abrirlo exige nuestras seis claves; vencer al origen y extraer la muestra será vuestra decisión.'}
];
const distance=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
export function magicState(p){return p.magic||(p.magic={known:[],mana:100,cooldowns:{},effects:{},shieldHp:0});}
export function effect(p,id,now){return (p.magic?.effects[id]||0)>now;}
export function clearSight(w,a,b){const steps=Math.ceil(distance(a,b)/.4);for(let i=1;i<steps;i++)if(solid(w,a.x+(b.x-a.x)*i/steps,a.y+(b.y-a.y)*i/steps,0))return false;return true;}

export function initializeStory(w,now=w.startedAt){
  if(w.story)return;
  const seed=[...w.id].reduce((n,c)=>n+c.charCodeAt(0),0);
  const anchors=w.legacy?[[50,12],[50,24],[50,36],[50,64],[50,76],[50,88]]:[[50,75],[50,105],[50,135],[160,75],[160,105],[160,135]];
  w.story={version:1,mages:anchors.map(([x,y],i)=>{
    const offset=(seed+i)%2?0:3;
    return {id:'mage-'+SPELLS[i].id,name:CHAPTERS[i].name,power:SPELLS[i].id,x,y:y+offset,home:{x,y},destination:y+offset,moveAt:now+180000+i*7000,visit:0};
  }),seal:w.legacy?{x:50,y:5}:{x:105,y:105},communities:Object.fromEntries(w.communities.map(c=>[c.id,{fragments:[],opened:false}]))};
  w.effects=[];
  for(const p of Object.values(w.players)){magicState(p);p.prologue=p.intro?2:0;}
}

export function reservedStorySite(w,x,y){
  return !!w.story&&(distance({x,y},w.story.seal)<7||w.story.mages.some(m=>Math.abs(x-m.home.x)<3&&Math.abs(y-m.home.y)<9));
}
export function announce(p,text,now){p.storyMessage={text,until:now+18000};}
export function interactStory(w,p,now){
  if(!w.story)return false;
  const v=core(w,p),radio={x:v.x,y:v.y+14};
  if(!p.prologue&&distance(p,radio)<=5){p.prologue=1;announce(p,'Radio recuperada: se perdió contacto con la ciudad. Una luz inutilizó el transporte y dispersó a los agentes. Alcanza la bóveda.',now);return true;}
  if(!p.intro&&(p.prologue||0)>=1&&distance(p,v)<=6){p.intro=true;p.prologue=2;announce(p,'La bóveda responde a una señal imposible. No es una infección normal. J abre el diario con las señales de seis supervivientes.',now);return true;}
  if(!p.intro)return false;
  const mage=w.story.mages.find(m=>distance(p,m)<=4&&clearSight(w,p,m));
  if(mage){const magic=magicState(p),progress=w.story.communities[p.communityId];
    if(!magic.known.includes(mage.power))magic.known.push(mage.power);
    if(!progress.fragments.includes(mage.power))progress.fragments.push(mage.power);
    announce(p,`${mage.name}: ${CHAPTERS[SPELLS.findIndex(s=>s.id===mage.power)].text}`,now);return true;
  }
  if(distance(p,w.story.seal)<=5&&clearSight(w,p,w.story.seal)){
    const progress=w.story.communities[p.communityId];
    if(progress.fragments.length<6){announce(p,`El encierro requiere seis claves. Tu comunidad conserva ${progress.fragments.length}/6.`,now);return true;}
    progress.opened=true;announce(p,'Las seis claves abren el encierro para tu comunidad. Acceso preparado. El enfrentamiento con el Paciente 0 llegará en la siguiente etapa.',now);return true;
  }
  return false;
}

export function cast(w,p,power,now){
  if(w.phase!=='active'||!p.alive)return false;
  const spell=SPELLS.find(s=>s.id===power),m=magicState(p);
  if(!spell||!p.intro||!m.known.includes(power)||m.mana<spell.cost||(m.cooldowns[power]||0)>now)return false;
  let targets=[];
  if(power==='heal'&&p.hp>=100)return false;
  if(power==='control'){
    targets=w.zombies.filter(z=>z.hp>0&&!z.boss&&(!z.charmUntil||z.charmUntil<=now)&&distance(z,p)<=12&&clearSight(w,p,z)).sort((a,b)=>distance(a,p)-distance(b,p)).slice(0,3);
    if(!targets.length)return false;
  }
  m.mana-=spell.cost;m.cooldowns[power]=now+spell.cooldown;
  if(power==='heal')p.hp=Math.min(100,p.hp+25);
  else if(power==='control')for(const z of targets){z.charmedBy=p.id;z.charmUntil=now+spell.duration;z.attack=0;}
  else {m.effects[power]=now+spell.duration;if(power==='shield')m.shieldHp=40;}
  w.effects.push({id:p.id+'-'+power+'-'+now,x:p.x,y:p.y,power,life:.7});return true;
}

export function storyTick(w,dt,now,online){
  if(!w.story)return;
  w.effects=w.effects.filter(f=>(f.life-=dt)>0);
  for(const m of w.story.mages){
    if(now>=m.moveAt){m.visit++;m.destination=m.home.y+(m.visit%2?6:0);m.moveAt=now+180000;}
    // Public, reserved corridors keep these short paths free of player walls.
    const next=m.y+Math.sign(m.destination-m.y)*Math.min(Math.abs(m.destination-m.y),dt*.8);
    if(!solid(w,m.x,next))m.y=next;
  }
  for(const p of Object.values(w.players)){const m=magicState(p);
    if(p.alive&&online.has(p.id)&&m.known.length)m.mana=Math.min(100,m.mana+dt*4);
    for(const key of Object.keys(m.effects))if(m.effects[key]<=now)delete m.effects[key];
    if(!effect(p,'shield',now))m.shieldHp=0;
  }
}

export function storyView(w,p){
  if(!w.story)return null;
  const progress=w.story.communities[p.communityId],v=core(w,p);
  return {radio:{x:v.x,y:v.y+14},prologue:p.prologue||0,seal:w.story.seal,opened:progress.opened,
    mages:p.intro?w.story.mages.map(({id,name,power,x,y})=>({id,name,power,x,y})):[],
    spells:p.intro?SPELLS:[],fragments:progress.fragments.map(id=>({id,text:CHAPTERS[SPELLS.findIndex(s=>s.id===id)].text})),message:p.storyMessage||null};
}
