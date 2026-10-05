import {workersTick} from './workers.mjs';
import {prepareWorkforce,workforce} from './population.mjs';
import {addMaterials,inventory,recipe,materialPlan,payRecipe,transferMaterials} from './inventory.mjs';
import {core,protectedRoad} from './communities.mjs';
import {randomUUID} from 'node:crypto';
import {damageInfected} from './loot.mjs';

export const STRUCTURES = Object.freeze({
  shelter:{name:'Refugio',cost:45,hp:300,width:3.2,depth:3.2,height:2.5,description:'Aloja dos rescatados del hospital. Cada trabajador ocupa un aserradero o cantera.'},
  sawmill:{name:'Aserradero',cost:60,hp:220,width:3.2,depth:3.2,height:1.8,description:'Un trabajador y un árbol vivo a 10 m: Extrae 6 madera en 20 s y la transporta al puesto. E recoge; capacidad 60.'},
  quarry:{name:'Cantera',cost:60,hp:300,width:3.2,depth:3.2,height:1.5,description:'Un trabajador y una roca viva a 10 m: Extrae 8 piedra en 20 s y la transporta al puesto. E recoge; capacidad 60.'},
  laboratory:{name:'Laboratorio del Sello',cost:100,hp:300,width:3.2,depth:3.2,height:2.2,description:'E investiga: 2 informes, 2 componentes y 20 materiales. Tres niveles: +1 recurso por golpe y +4 daño de torreta. Con muestra, 6 claves y 3 informes sintetiza la cura.'},
  turret:{name:'Torreta',cost:80,hp:220,width:2.4,depth:2.4,height:2.2,description:'Dispara a infectados a 14 m. Necesita generador a 8 m y munición. E: cargar hasta 30 balas.'},
  generator:{name:'Generador',cost:70,hp:280,width:2.4,depth:2.4,height:1.4,description:'E: 20 materiales para 90 s de energía a 8 m. Alimenta torretas y recicladores.'},
  recycler:{name:'Reciclador',cost:65,hp:240,width:3.2,depth:3.2,height:1.5,description:'Con energía: E convierte 10 balas de reserva en 3 materiales, cada 10 s.'},
  kitchen:{name:'Cocina',cost:55,hp:200,width:3.2,depth:3.2,height:1.5,description:'E: consume 1 comida y 1 agua para recuperar 60 alimento y 15 PV.'},
  raincollector:{name:'Recolector de agua',cost:30,hp:140,width:2.4,depth:2.4,height:1.3,description:'Produce agua cada 45 s, hasta 5 usos. E: beber y recuperar 40 hidratación.'},
  sandbag:{name:'Sacos defensivos',cost:10,hp:100,width:3.2,depth:1.2,height:1,description:'Defensa económica: bloquea movimiento y disparos. Reparación y mejoras disponibles.'},
  wall:{name:'Muro',cost:20,hp:180,width:3.2,depth:1.2,height:2.4,description:'Defensa modular. Encaja por sus extremos.'},
  gate:{name:'Portón',cost:30,hp:240,width:3.2,depth:1.2,height:2.4,description:'E abre/cierra. Abierto deja pasar agentes, zombis y disparos.'},
  spikes:{name:'Pinchos',cost:15,hp:90,width:3.2,depth:1.2,height:.6,description:'Transitables. Dañan infectados y se desgastan.'},
  workshop:{name:'Taller',cost:60,hp:300,width:3.2,depth:3.2,height:1.5,description:'E: 30 balas por 15 materiales. Clic derecho: reforzar blindaje por 25.'},
  infirmary:{name:'Enfermería',cost:50,hp:260,width:3.2,depth:3.2,height:1.7,description:'E: recupera 35 PV por 10 materiales.'},
  well:{name:'Pozo',cost:40,hp:300,width:3.2,depth:3.2,height:1.5,description:'Agua cada 30 s. E: +40 hidratación. Riega huertos aliados a 6 m.'},
  garden:{name:'Huerto',cost:45,hp:160,width:3.2,depth:3.2,height:.4,description:'Produce comida cada 60 s, hasta 5 usos. E: +35 alimento.'},
  storage:{name:'Almacén',cost:35,hp:280,width:3.2,depth:3.2,height:1.5,description:'Depósito aliado de materiales y balas. T guarda materiales; E retira. Clic derecho: munición.'}
});
export const catalog = () => ['wall','gate','spikes','workshop','infirmary','well','garden','storage','turret','generator','recycler','kitchen','raincollector','sandbag','shelter','sawmill','quarry','laboratory'].map(id=>({id,...STRUCTURES[id],recipe:recipe(STRUCTURES[id].cost,id)}));
export const definition = b => Object.hasOwn(STRUCTURES,b.kind||'wall')?STRUCTURES[b.kind||'wall']:STRUCTURES.wall;
export function bounds(b){const d=definition(b);return b.rot===1?{x:d.depth/2,y:d.width/2}:{x:d.width/2,y:d.depth/2};}
export const isSolid = b => !(b.kind==='spikes'||b.kind==='gate'&&b.open);
export function contains(b,x,y,r=0){const h=bounds(b);return Math.abs(b.x-x)<h.x+r&&Math.abs(b.y-y)<h.y+r;}
export const quantize = n => Math.round(n*5)/5;
export const productionInterval = (w,b) => (b.kind==='well'?30000:b.kind==='raincollector'?45000:b.kind==='garden'?60000:0)/(b.kind==='raincollector'&&w.adventure?.weather==='rain'?2:1)/(1+(b.level||0)*.25)/(b.kind==='garden'&&w.walls.some(q=>q.kind==='well'&&q.hp>0&&q.communityId===b.communityId&&Math.hypot(q.x-b.x,q.y-b.y)<=6)?1.25:1);
export const powered = (w,b,now) => w.walls.some(g=>g.kind==='generator'&&g.hp>0&&g.communityId===b.communityId&&(g.fuelUntil||0)>now&&Math.hypot(g.x-b.x,g.y-b.y)<=8);
function clearShot(w,b,z){const distance=Math.hypot(b.x-z.x,b.y-z.y);for(let t=1.7;t<distance;t+=.4){const x=b.x+(z.x-b.x)*t/distance,y=b.y+(z.y-b.y)*t/distance;if(w.walls.some(q=>q!==b&&q.hp>0&&isSolid(q)&&contains(q,x,y))||(w.obstacles||[]).some(q=>Math.abs(q.x-x)<q.sx&&Math.abs(q.y-y)<q.sy))return false;}return true;}
export const storageCapacity = b => 200+(b.level||0)*100;
const occupiedGate = (w,b) => [...Object.values(w.players).filter(p=>p.alive),...w.zombies.filter(z=>z.hp>0),...(w.workers||[])].some(q=>contains(b,q.x,q.y,.65));

export function structureAction(w,p,b,type,now){
  const fail=message=>{p.buildError=message;return false;};
  if(!p.alive||!b||b.hp<=0||b.communityId!==p.communityId)return fail('Selecciona una estructura viva de tu comunidad.');
  if(['staff','unstaff'].includes(type)){
    const v=core(w,p);if(Math.hypot(p.x-v.x,p.y-v.y)>24+(v.upgrades||0)*6)return fail('Acércate a tu base para dar órdenes a los trabajadores.');
  }else if(Math.hypot(p.x-b.x,p.y-b.y)>4.5)return fail('Acércate a menos de 4,5 m para usar esta estructura.');
  if(['staff','unstaff'].includes(type)&&['sawmill','quarry'].includes(b.kind)){
    b.staffed=type==='staff';b.staffPriority=now;
    p.actionMessage=b.staffed?'Puesto priorizado: recibirá el primer trabajador disponible':'Puesto pausado: trabajador liberado';return true;
  }
  if(type==='supply_workers'&&b.kind==='shelter'){
    if(!(p.food>0&&p.water>0))return fail('Necesitas 1 comida y 1 agua en la mochila.');
    const c=w.communities.find(c=>c.id===p.communityId);if(!(c.settlers>0))return fail('Primero rescata población en un hospital.');
    const state=workforce(c,now);if(state.food>=30||state.water>=30)return fail('La reserva común está llena (30 de cada suministro).');
    p.food--;p.water--;state.food++;state.water++;p.actionMessage='Donados 1 comida y 1 agua para la población';return true;
  }
  if(type==='armor'&&b.kind==='workshop'){
    if(p.armor>=100)return fail('Tu blindaje ya está completo.');
    if(p.wood<25)return fail('Reforzar el blindaje cuesta 25 materiales.');
    p.wood-=25;p.armor=Math.min(100,p.armor+30+(b.level||0)*10);p.actionMessage='Blindaje reforzado';return true;
  }
  if(type==='auto_close'&&b.kind==='gate'){
    b.autoClose=!b.autoClose;b.closeAt=b.autoClose&&b.open?now+5000:0;p.actionMessage=b.autoClose?'Cierre automático activado: 5 segundos':'Cierre automático desactivado';return true;
  }
  if(b.kind==='storage'){
    if(type==='deposit_materials'){
      const n=Math.min(20,p.wood,Math.max(0,storageCapacity(b)-(b.stock||0)));
      if(n<=0)return fail(p.wood<=0?'No tienes materiales para guardar.':'El almacén de materiales está lleno.');
      transferMaterials(p,b,true,n);p.actionMessage=`Guardados ${n} materiales`;return true;
    }
    if(type==='deposit_ammo'||type==='withdraw_ammo'){
      const deposit=type==='deposit_ammo',n=Math.min(30,deposit?p.reserve:(b.ammoStock||0),deposit?Math.max(0,120+(b.level||0)*60-(b.ammoStock||0)):Infinity);
      if(n<=0)return fail(deposit?'No tienes balas de reserva o el almacén está lleno.':'No hay munición almacenada.');
      p.reserve+=deposit?-n:n;b.ammoStock=(b.ammoStock||0)+(deposit?n:-n);p.actionMessage=`${deposit?'Guardadas':'Retiradas'} ${n} balas`;return true;
    }
  }
  return fail('Esta función no corresponde a la estructura seleccionada.');
}

export function structureStatus(w,b,now){
  const level=b.level||0,interval=productionInterval(w,b);
  const info={wall:'Bloquea movimiento y disparos; los infectados deben rodearlo o destruirlo.',gate:b.open?'Paso abierto: pueden atravesarlo personas, infectados y disparos.':'Paso cerrado: bloquea movimiento y disparos.',spikes:`Trampa automática: ${18+level*6} daño por segundo; pierde 5 PV por ataque. No daña infectados controlados.`,workshop:`Fabrica ${30+level*6} balas por 15 materiales. Refuerza ${30+level*10} de blindaje por 25.`,infirmary:`Recupera hasta ${35+level*10} PV por 10 materiales.`,well:'Agua: +40 hidratación por uso. Riega huertos aliados a 6 m: producción +25%.',garden:'Comida: +35 alimento por uso. Construye un pozo a 6 m para acelerar la cosecha.',storage:`Depósito compartido: ${b.stock||0}/${storageCapacity(b)} materiales y ${b.ammoStock||0}/${120+level*60} balas.`};
  let description=info[b.kind||'wall']||definition(b).description;
  if(['turret','recycler'].includes(b.kind))description+=powered(w,b,now)?' Energía: ACTIVA.':' Sin energía: activa un generador cercano.';
  if(['sawmill','quarry'].includes(b.kind))description+=` ${b.workerReason||'Esperando asignación.'} Reserva: ${b.stock||0}/60.`;
  if(b.kind==='shelter'){const c=w.communities.find(c=>c.id===b.communityId);description+=` Rescatados: ${c?.settlers||0}. Plazas: ${w.walls.filter(q=>q.kind==='shelter'&&q.hp>0&&q.communityId===b.communityId).length*2}.`;}
  if(b.kind==='laboratory'){const c=w.communities.find(c=>c.id===b.communityId);description+=` Informes: ${c?.research||0}. Investigación: ${c?.tech||0}/3.`;}
  if(b.kind==='turret')description+=` Munición: ${b.ammoStock||0}/60.`;
  if(b.kind==='generator')description+=` Energía restante: ${Math.max(0,Math.ceil(((b.fuelUntil||0)-now)/1000))} s.`;
  return {description,nextProduction:interval?Math.max(0,Math.ceil(((b.producedAt??now)+interval-now)/1000)):0,interval:interval/1000,capacity:interval?5:0};
}

// The client sends endpoints; the authority derives and validates every piece.
export function buildRow(w,p,msg,now){
  if(!['wall','gate','spikes'].includes(msg.kind)||![msg.x,msg.y,msg.endX,msg.endY].every(Number.isFinite))return false;
  const x=quantize(msg.x),y=quantize(msg.y),dx=msg.endX-x,dy=msg.endY-y;
  const vertical=Math.abs(dy)>Math.abs(dx),steps=Math.round(Math.abs(vertical?dy:dx)/3.2);
  if(steps>19)return false;
  const direction=Math.sign(vertical?dy:dx)||1,rot=vertical?1:0,planned=[],d=STRUCTURES[msg.kind];
  const shadow={...w,walls:[...w.walls]},payer={...p,materials:{...inventory(p)}};
  for(let i=0;i<=steps;i++){
    const point={x:quantize(x+(vertical?0:i*3.2*direction)),y:quantize(y+(vertical?i*3.2*direction:0))};
    const reason=placementReason(shadow,payer,point.x,point.y,msg.kind,rot,true);
    if(reason){p.buildError=reason;return false;}
    const b={id:randomUUID(),communityId:p.communityId,kind:msg.kind,...point,rot,hp:d.hp,maxHp:d.hp,open:false,stock:0,producedAt:now};
    planned.push(b);shadow.walls.push(b);payRecipe(payer,d.cost,msg.kind);
  }
  p.wood=payer.wood;p.materials=payer.materials;p.buildError='';w.walls.push(...planned);return true;
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
  if(!p.alive||w.phase!=='active')return 'No puedes construir ahora';
  if(p.wood<d.cost)return 'Materiales insuficientes';
  if(!materialPlan(p,d.cost,kind))return 'Receta: '+Object.entries(recipe(d.cost,kind)).map(([k,n])=>n+' '+({timber:'madera',stone:'piedra',scrap:'chatarra'}[k])).join(' + ')+'. Los recuperados sustituyen cualquier material.';
  if(w.walls.filter(b=>(b.communityId||'forest')===p.communityId).length>=80)return 'Límite de 80 estructuras';
  if(v.hp<=0)return 'Tu bóveda fue destruida: ya no puedes construir en esta comunidad';
  if(distance>=radius)return `Fuera del límite azul: coloca el plano a menos de ${radius} m de tu bóveda (ahora ${Math.ceil(distance)} m). U junto a la bóveda amplía el territorio.`;
  if(distance<=4)return 'Deja libre el círculo rojo alrededor de la bóveda: coloca el plano más allá de 4 m';
  if(remote?Math.hypot(p.x-v.x,p.y-v.y)>radius+6:Math.hypot(p.x-x,p.y-y)>=9)return 'Acércate a tu base';
  if(x-h.x<2||y-h.y<2||x+h.x>w.size-2||y+h.y>w.size-2)return 'Fuera del mapa';
  if(protectedRoad(w,x,y))return 'Corredor público reservado';
  if(w.story&&(Math.hypot(x-w.story.seal.x,y-w.story.seal.y)<7||w.story.mages.some(m=>Math.abs(x-m.home.x)<3&&Math.abs(y-m.home.y)<9)))return 'Zona de historia reservada';
  if((w.obstacles||[]).some(o=>Math.abs(o.x-x)<o.sx+h.x&&Math.abs(o.y-y)<o.sy+h.y))return 'Obstáculo en el terreno';
  if((w.resources||[]).some(r=>r.hits>0&&Math.abs(r.x-x)<h.x+1&&Math.abs(r.y-y)<h.y+1))return 'Tala o extrae el recurso antes de construir aquí';
  if(w.walls.some(o=>{const a=bounds(o);return Math.abs(o.x-x)<a.x+h.x-.001&&Math.abs(o.y-y)<a.y+h.y-.001;}))return 'Se solapa con otra estructura';
  if(Object.values(w.players).some(q=>q.alive&&contains(b,q.x,q.y,.65))||w.zombies.some(z=>z.hp>0&&contains(b,z.x,z.y,.65))||(w.workers||[]).some(q=>contains(b,q.x,q.y,.65)))return 'Hay alguien en el plano';
  return '';
}

export function useStructure(w,p,b,now){
  const fail=message=>{p.buildError=message;return false;};
  if(!b||b.hp<=0||b.communityId!==p.communityId)return fail('Selecciona una estructura de tu comunidad.');
  if(Math.hypot(p.x-b.x,p.y-b.y)>4.5)return fail('Acércate a menos de 4,5 m para usarla.');
  switch(b.kind){
    case 'shelter': p.actionMessage='Rescata población en hospitales. Clic derecho: donar comida y agua. Aserraderos y canteras: priorizar o pausar puestos.';return true;
    case 'sawmill': case 'quarry': if(!(b.stock>0))return fail('Sin producción: necesitas refugio, rescatados y un recurso vivo a 10 m.');addMaterials(p,b.kind==='sawmill'?'timber':'stone',b.stock);p.actionMessage='Recogidos '+b.stock+' '+(b.kind==='sawmill'?'madera':'piedra');b.stock=0;return true;
    case 'laboratory': {
      const c=w.communities.find(c=>c.id===p.communityId),progress=w.story.communities[c.id];inventory(p);
      if(p.sample){
        if(now>=w.startedAt+30*86400000){w.phase='expired';return fail('El plazo de treinta días ha vencido.');}
        const survivors=w.communities.filter(q=>!q.eliminated&&Object.values(w.players).some(agent=>agent.communityId===q.id));
        if(survivors.length!==1||survivors[0].id!==c.id)return fail('La victoria mayor requiere una única comunidad superviviente.');
        if(!w.story.patient?.defeated||w.story.patient.defeatedBy!==c.id)return fail('Tu comunidad debe derrotar al Paciente 0 para reclamar la cura.');
        if(progress.fragments.length<6||(c.research||0)<3)return fail('La cura necesita las seis claves y 3 informes de expedición.');
        p.sample=false;c.research-=3;w.phase='victory';w.winner=c.id;w.completedAt=now;
        for(const ally of Object.values(w.players).filter(q=>q.communityId===c.id))ally.reward={worldId:w.id,title:'Custodio del Sello',completedAt:now};
        p.actionMessage='Cura sintetizada. Tu comunidad ha sobrevivido al Cerco.';return true;
      }
      if((c.tech||0)>=3)return fail('Investigación completa. Busca al Paciente 0 y trae su muestra.');
      if((c.research||0)<2||p.materials.components<2||p.wood-p.materials.components<20)return fail('Investigar requiere 2 informes, 2 componentes y 20 materiales.');
      c.research-=2;p.materials.components-=2;p.wood-=22;inventory(p);c.tech=(c.tech||0)+1;p.actionMessage='Investigación '+c.tech+'/3: extracción y torretas mejoradas';return true;
    }
    case 'generator': if(p.wood<20)return fail('Activar el generador cuesta 20 materiales.');if((b.fuelUntil||0)>now)return fail('El generador ya está activo. Espera a que se agote.');p.wood-=20;b.fuelUntil=now+90000+(b.level||0)*30000;p.actionMessage='Generador encendido';return true;
    case 'turret': {const n=Math.min(30,p.reserve,60-(b.ammoStock||0));if(n<=0)return fail('La torreta está llena o no tienes munición de reserva.');p.reserve-=n;b.ammoStock=(b.ammoStock||0)+n;p.actionMessage=`Torreta cargada: +${n} balas`;return true;}
    case 'recycler': if(!powered(w,b,now))return fail('Activa un generador a menos de 8 m.');if((b.recycleAfter||0)>now)return fail('El reciclador se enfría durante 10 segundos.');if(p.reserve<10)return fail('Necesitas 10 balas de reserva.');p.reserve-=10;p.wood+=3;b.recycleAfter=now+10000;p.actionMessage='Reciclados 3 materiales';return true;
    case 'kitchen': if(p.hunger>=100&&p.hp>=100)return fail('Tu salud y alimento están completos.');if(!(p.food>0&&p.water>0))return fail('Necesitas 1 comida y 1 agua en tu mochila.');p.food--;p.water--;p.hunger=Math.min(100,p.hunger+60);p.hp=Math.min(100,p.hp+15);p.actionMessage='Comida preparada: +60 alimento y +15 PV';return true;
    case 'gate':
      if((b.toggleAfter||0)>now)return false;
      if(b.open&&occupiedGate(w,b))return fail('Hay alguien en el paso. El portón no puede cerrarse.');
      b.open=!b.open;b.toggleAfter=now+300;b.closeAt=b.autoClose&&b.open?now+5000:0;p.actionMessage=b.open?'Portón abierto':'Portón cerrado';return true;
    case 'workshop': if(p.wood<15)return fail('Necesitas 15 materiales para fabricar munición.');p.wood-=15;p.reserve+=30+(b.level||0)*6;p.actionMessage='Munición fabricada';return true;
    case 'infirmary': if(p.hp>=100)return fail('Tu salud ya está completa.');if(p.wood<10)return fail('Necesitas 10 materiales para curarte.');p.wood-=10;p.hp=Math.min(100,p.hp+35+(b.level||0)*10);p.actionMessage='Tratamiento completado';return true;
    case 'raincollector': case 'well': if(p.thirst>=100)return fail('Tu hidratación ya está completa.');if((b.stock||0)<1)return fail('Aún está produciendo agua. Consulta el tiempo en su ficha.');b.stock--;p.thirst=Math.min(100,p.thirst+40);p.actionMessage='Has bebido agua: +40 hidratación';return true;
    case 'garden': if(p.hunger>=100)return fail('Ya estás bien alimentado.');if((b.stock||0)<1)return fail('La cosecha aún está creciendo. Consulta el tiempo en su ficha.');b.stock--;p.hunger=Math.min(100,p.hunger+35);p.actionMessage='Has comido: +35 alimento';return true;
    case 'storage': {const n=Math.min(20,b.stock||0);if(!n)return fail('No hay materiales almacenados.');transferMaterials(p,b,false,n);p.actionMessage=`Retirados ${n} materiales`;return true;}
  }return false;
}

export function structuresTick(w,dt,now,online=null){
  const assigned=prepareWorkforce(w,online,now);
  workersTick(w,assigned,online,dt,now);
  for(const b of w.walls){
    if(b.hp<=0)continue;
    if(b.kind==='turret'&&(b.attackAfter||0)<=now&&(b.ammoStock||0)>0&&powered(w,b,now)){
      const target=w.zombies.filter(z=>z.hp>0&&!(z.charmUntil>now)&&Math.hypot(z.x-b.x,z.y-b.y)<=14).sort((a,c)=>Math.hypot(a.x-b.x,a.y-b.y)-Math.hypot(c.x-b.x,c.y-b.y)).find(z=>clearShot(w,b,z));
      if(target){b.ammoStock--;b.attackAfter=now+1000;b.aim=Math.atan2(target.y-b.y,target.x-b.x);damageInfected(w,target,24+(b.level||0)*6+(w.communities.find(c=>c.id===b.communityId)?.tech||0)*4,now,b.communityId);w.shots.push({x:b.x,y:b.y,angle:b.aim,length:Math.hypot(target.x-b.x,target.y-b.y),life:.12});}
    }
    if(b.kind==='gate'&&b.open&&b.autoClose&&now>=(b.closeAt||0)&&!occupiedGate(w,b))b.open=false;
    const interval=productionInterval(w,b);
    if(interval){b.producedAt??=now;const count=Math.floor((now-b.producedAt)/interval);if(count>0){b.stock=Math.min(5,(b.stock||0)+count);b.producedAt+=count*interval;}}
    if(b.kind==='spikes'&&(b.attackAfter||0)<=now){
      const targets=w.zombies.filter(z=>z.hp>0&&!(z.charmUntil>now)&&contains(b,z.x,z.y,.5));
      if(targets.length){for(const z of targets){damageInfected(w,z,18+(b.level||0)*6,now,b.communityId);}b.hp=Math.max(0,b.hp-5);b.attackAfter=now+1000;}
    }
  }
}
