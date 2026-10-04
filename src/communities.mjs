export const REGIONS = [
  {id:'forest',name:'Vigías del Bosque',region:'Bosque',x:50,y:50,color:'#c6e78a',ground:'#294335',resources:{wood:30,ammo:12}},
  {id:'mountain',name:'Guardia de la Cumbre',region:'Montaña',x:50,y:160,color:'#a9c8e8',ground:'#384a48',resources:{wood:55,ammo:4}},
  {id:'city',name:'Pacto del Asfalto',region:'Ciudad',x:160,y:50,color:'#e5b57e',ground:'#45493f',resources:{wood:18,ammo:30}},
  {id:'underground',name:'Custodios del Umbral',region:'Subterráneo',x:160,y:160,color:'#c4a4e5',ground:'#343844',resources:{wood:40,ammo:18}}
];
export const SIEGE_PRESETS = {
  development:{enabled:true,delayMs:120000,cycleMs:300000,windowMs:90000,requireDefenders:true},
  production:{enabled:true,delayMs:10*86400000,cycleMs:86400000,windowMs:7200000,requireDefenders:true}
};

export function makeCommunities(){return REGIONS.map(r=>({...r,vault:{x:r.x,y:r.y,hp:1500,maxHp:1500,upgrades:0},stock:100,eliminated:false}));}
export const faction = (w,p) => w.communities?.find(c=>c.id===(typeof p==='string'?p:p?.communityId))||w.communities?.[0];
export const core = (w,p) => faction(w,p)?.vault||w.vault;
export const vaults = w => w.communities?.map(c=>c.vault)||[w.vault];
export const capacity = w => (w.communities?.length||1)*10;
export const members = (w,c) => Object.values(w.players).filter(p=>(p.communityId||'forest')===c.id);
export const activeMembers = (w,c) => members(w,c).some(p=>p.alive);

export function siegeStatus(w,now=Date.now()){
  const r=w.rules?.siege||{enabled:false},start=w.startedAt+(r.delayMs||0);
  if(!r.enabled||w.phase!=='active')return {active:false,remaining:0,enabled:false};
  if(now<start)return {active:false,remaining:start-now,enabled:true};
  const elapsed=(now-start)%r.cycleMs;
  return {active:elapsed<r.windowMs,remaining:elapsed<r.windowMs?r.windowMs-elapsed:r.cycleMs-elapsed,enabled:true};
}
export function canRaid(w,attacker,targetId,online,now){
  const own=faction(w,attacker),target=faction(w,targetId);
  return !!(own&&target&&own.id!==target.id&&!own.eliminated&&!target.eliminated&&members(w,target).length&&siegeStatus(w,now).active&&(!w.rules.siege.requireDefenders||members(w,target).some(p=>p.alive&&online.has(p.id))));
}
export function protectedRoad(w,x,y){
  if(w.legacy)return Math.abs(x-50)<3;
  return Math.abs(x-50)<3||Math.abs(x-160)<3||Math.abs(y-105)<3;
}
export function checkElimination(w){
  for(const c of w.communities||[])if(c.vault.hp<=0&&members(w,c).length&&!activeMembers(w,c))c.eliminated=true;
  const enrolled=(w.communities||[]).filter(c=>members(w,c).length);
  if(enrolled.length&&enrolled.every(c=>c.eliminated))w.phase='defeat';
}
