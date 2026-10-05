// Account cosmetics are separate from world inventory. The ledger and balances
// are saved atomically in the same JSON replacement as the completed world.
export function profileFor(data,identity){
  identity.profileId??=identity.id;
  data.profiles??={};
  return data.profiles[identity.profileId]??={coins:0,seals:0,titles:[],rewards:{}};
}
export function settleRewards(data){
  for(const w of data.worlds){
    if(w.phase!=='victory'||!w.winner||w.completedAt>=w.startedAt+30*86400000)continue;
    for(const account of Object.values(data.accounts)){
      if(account.worldId!==w.id)continue;
      const p=w.players[account.id];if(!p||p.communityId!==w.winner)continue;
      const profile=profileFor(data,account);if(profile.rewards[w.id])continue;
      const contribution=(p.kills||0)+(p.expeditions||0)+Object.values(p.journey||{}).filter(Boolean).length+(p.magic?.known?.length||0);
      const coins=contribution?12:0,seals=contribution?1:0;
      profile.coins+=coins;profile.seals+=seals;
      if(!profile.titles.includes('Custodio del Sello'))profile.titles.push('Custodio del Sello');
      profile.rewards[w.id]={coins,seals,completedAt:w.completedAt};
    }
  }
}
export function cosmetics(data,worldId,playerId){
  const identity=Object.values(data.accounts).find(a=>a.worldId===worldId&&a.id===playerId);
  if(!identity)return {coins:0,seals:0,titles:[]};
  const profile=profileFor(data,identity);
  return {coins:profile.coins,seals:profile.seals,titles:profile.titles,owned:profile.owned||['standard'],equipped:profile.equipped||'standard',catalog:COSMETICS};
}

export const COSMETICS={standard:{name:'Guardia',coins:0,seals:0,color:'#81917b'},ember:{name:'Brasa',coins:6,seals:0,color:'#df8e43'},mist:{name:'Niebla',coins:6,seals:0,color:'#7bc1bd'},seal:{name:'Custodio',coins:12,seals:1,color:'#b297de'}};
export function cosmeticAction(data,w,p,msg){
  if(!Number.isSafeInteger(msg.seq)||msg.seq<=p.seq)return false;
  p.seq=msg.seq;
  const identity=Object.values(data.accounts).find(a=>a.worldId===w.id&&a.id===p.id);
  if(!identity||!Object.hasOwn(COSMETICS,msg.style)){p.buildError='Aspecto desconocido';return false;}
  const profile=profileFor(data,identity),item=COSMETICS[msg.style];profile.owned??=['standard'];
  if(!profile.owned.includes(msg.style)){
    if(profile.coins<item.coins||profile.seals<item.seals){p.buildError=`Necesitas ${item.coins} monedas y ${item.seals} sellos. Se obtienen al completar una campaña.`;return false;}
    profile.coins-=item.coins;profile.seals-=item.seals;profile.owned.push(msg.style);
  }
  profile.equipped=msg.style;
  for(const account of Object.values(data.accounts)){
    if((account.profileId||account.id)!==identity.profileId)continue;
    const player=data.worlds.find(world=>world.id===account.worldId)?.players[account.id];
    if(player)player.appearance=msg.style;
  }
  p.actionMessage='Aspecto equipado: '+item.name;return true;
}
