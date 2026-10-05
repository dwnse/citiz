import {addMaterials} from './inventory.mjs';

const incidents={
  hospital:{title:'La radio de los vivos',description:'Recupera el botiquín de emergencia antes de que se pierda la señal.',reward:'3 botiquines y 2 comidas'},
  station:{title:'Agua bajo el óxido',description:'La bomba auxiliar funciona por unos minutos. Recupera sus reservas.',reward:'6 aguas y 20 chatarra'},
  laboratory:{title:'El eco del Umbral',description:'Un terminal ha despertado. Recupera sus componentes antes del apagado.',reward:'4 componentes y 24 balas'}
};
export function incidentTick(w,online){
  const a=w.adventure;
  a.incidentNext??=120;a.incidentIndex??=0;a.incidentHistory??=[];
  if(a.incident&&a.elapsed>=a.incident.endsAt){
    a.incidentHistory.push({...a.incident,result:'Señal perdida'});a.incidentHistory=a.incidentHistory.slice(-6);a.incident=null;
  }
  if(a.incident||a.elapsed<a.incidentNext)return;
  const eligible=a.sites.filter(s=>w.communities.some(c=>s.id.startsWith(c.id+'-')&&c.vault.hp>0&&Object.values(w.players).some(p=>p.communityId===c.id&&p.alive&&online.has(p.id))));
  if(!eligible.length)return;
  const site=eligible[a.incidentIndex++%eligible.length],definition=incidents[site.kind];
  a.incident={...definition,id:'signal-'+a.incidentIndex,siteId:site.id,kind:site.kind,x:site.x,y:site.y,endsAt:a.elapsed+120};
  a.incidentNext=a.elapsed+300;
}
export function claimIncident(w,p,site){
  const a=w.adventure,event=a.incident;
  if(!event||event.siteId!==site.id||a.elapsed>=event.endsAt)return false;
  if(event.kind==='hospital'){p.medical=(p.medical||0)+3;p.food=(p.food||0)+2;}
  if(event.kind==='station'){p.water=(p.water||0)+6;addMaterials(p,'scrap',20);}
  if(event.kind==='laboratory'){addMaterials(p,'components',4);p.reserve+=24;}
  p.signalsRecovered=(p.signalsRecovered||0)+1;
  a.incidentHistory??=[];a.incidentHistory.push({...event,result:'Recuperada por '+p.name});a.incidentHistory=a.incidentHistory.slice(-6);
  a.incident=null;return event;
}
