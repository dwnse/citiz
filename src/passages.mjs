import {solid} from './navigation.mjs';
import {clearSight} from './story.mjs';

export const PASSAGES=[
 {id:'drain-nw',name:'Colector del norte',x:50,y:96,to:'drain-se'},
 {id:'drain-se',name:'Salida de las cenizas',x:160,y:114,to:'drain-nw'},
 {id:'drain-sw',name:'Colector del sur',x:50,y:114,to:'drain-ne'},
 {id:'drain-ne',name:'Salida del Umbral',x:160,y:96,to:'drain-sw'}
];
export function passages(w){return w.legacy?[]:PASSAGES;}
export function travel(w,p,now){
 const fail=message=>{p.buildError=message;return false;};
 const entry=passages(w).find(t=>Math.hypot(t.x-p.x,t.y-p.y)<=3);
 if(!entry)return fail('Acércate a la entrada señalada del colector.');
 if(!clearSight(w,p,entry))return fail('Rodea el obstáculo hasta la entrada del colector.');
 if(p.travelAfter>now)return fail('Recupera el aliento: colector disponible en '+Math.ceil((p.travelAfter-now)/1000)+' s.');
 if((p.stamina??100)<25)return fail('Cruzar el colector requiere 25 de resistencia.');
 const destination=PASSAGES.find(t=>t.id===entry.to);
 let exit=null;
 for(let radius=0;radius<=4&&!exit;radius++)for(let i=0;i<12;i++){
   const q={x:destination.x+Math.cos(i*Math.PI/6)*radius,y:destination.y+Math.sin(i*Math.PI/6)*radius};
   if(!solid(w,q.x,q.y)&&![...Object.values(w.players).filter(p=>p.alive),...w.zombies.filter(z=>z.hp>0),...(w.workers||[])].some(p=>Math.hypot(p.x-q.x,p.y-q.y)<2)){exit=q;break;}
 }
 if(!exit)return fail('Salida bloqueada. Despeja el otro acceso antes de cruzar.');
 p.stamina=(p.stamina??100)-25;p.travelAfter=now+15000;p.noiseUntil=now+20000;p.x=exit.x;p.y=exit.y;p.sprinting=false;
 p.actionMessage=destination.name+': has cruzado el colector. El eco atrae infectados.';return true;
}
