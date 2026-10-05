export const MATERIAL_NAMES={reclaimed:'recuperados',timber:'madera',stone:'piedra',scrap:'chatarra',components:'componentes'};
// wood is the legacy total. Reconcile older saves and legacy economy actions without losing value.
export function inventory(p){
  p.materials??={reclaimed:p.wood||0,timber:0,stone:0,scrap:0,components:0};
  for(const key of Object.keys(MATERIAL_NAMES))p.materials[key]??=0;
  let difference=(p.wood||0)-Object.values(p.materials).reduce((a,b)=>a+b,0);
  if(difference>0)p.materials.reclaimed+=difference;
  if(difference<0)for(const key of Object.keys(MATERIAL_NAMES)){const n=Math.min(p.materials[key],-difference);p.materials[key]-=n;difference+=n;}
  return p.materials;
}
export function addMaterials(p,key,n){inventory(p);p.materials[key]+=n;p.wood+=n;}
export function recipe(cost,kind){
  const primary=['wall','gate','garden','storage','house','sawmill','shelter'].includes(kind)?'timber':['well','sandbag','infirmary','quarry'].includes(kind)?'stone':'scrap';
  return {[primary]:Math.ceil(cost*.7),[primary==='stone'?'timber':'stone']:Math.floor(cost*.3)};
}
export function materialPlan(p,cost,kind){
  const stock={...inventory(p)},payment={};
  for(const [key,amount] of Object.entries(recipe(cost,kind))){
    const n=Math.min(stock[key],amount);stock[key]-=n;payment[key]=n;
    const rest=amount-n;if(stock.reclaimed<rest)return null;stock.reclaimed-=rest;payment.reclaimed=(payment.reclaimed||0)+rest;
  }return payment;
}
export function payRecipe(p,cost,kind){const plan=materialPlan(p,cost,kind);if(!plan)return false;for(const [key,n] of Object.entries(plan))p.materials[key]-=n;p.wood-=cost;return true;}
export function transferMaterials(p,b,deposit,amount){
  inventory(p);b.materials??={reclaimed:b.stock||0,timber:0,stone:0,scrap:0,components:0};
  const source=deposit?p.materials:b.materials,target=deposit?b.materials:p.materials;
  let remaining=amount;
  for(const key of Object.keys(MATERIAL_NAMES)){const n=Math.min(source[key]||0,remaining);source[key]=(source[key]||0)-n;target[key]=(target[key]||0)+n;remaining-=n;}
  const moved=amount-remaining;p.wood+=deposit?-moved:moved;b.stock=(b.stock||0)+(deposit?moved:-moved);return moved;
}
