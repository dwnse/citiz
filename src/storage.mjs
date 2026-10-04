import {existsSync,readFileSync,writeFileSync,renameSync,copyFileSync,mkdirSync,openSync,fsyncSync,closeSync} from 'node:fs';
import {createWorld} from './world.mjs';
import {REGIONS} from './communities.mjs';
import {initializeStory} from './story.mjs';

export function migrate(data) {
  if(data.version===1) {
    const world=structuredClone(data.world);
    world.version=2;world.name='Bosque original';world.obstacles=[];
    return migrate({version:2,worlds:[world],accounts:Object.fromEntries(Object.entries(data.accounts).map(([key,id])=>[key,{id,worldId:world.id}]))});
  }
  if(![2,3,4,5].includes(data.version))throw Error('Versión de guardado desconocida; se requiere migración explícita');
  if(!Array.isArray(data.worlds)||!data.worlds.length||!data.accounts)throw Error('Guardado incompleto');
  if(data.version===2){data=structuredClone(data);for(const w of data.worlds){
    w.version=3;w.size=100;w.legacy=true;w.rules={siege:{enabled:false}};delete w.story;delete w.effects;
    w.communities=[{...REGIONS[0],name:'Comunidad de legado',vault:w.vault,stock:100,eliminated:w.phase==='defeat'}];
    for(const p of Object.values(w.players))p.communityId='forest';for(const b of w.walls)b.communityId='forest';for(const z of w.zombies)z.communityId='forest';
  }data.version=3;}
  for(const w of data.worlds)w.vault=w.communities[0].vault;
  if(data.version===3){data=structuredClone(data);for(const w of data.worlds){w.vault=w.communities[0].vault;w.version=4;delete w.story;initializeStory(w);}data.version=4;}
  if(data.version===4){data=structuredClone(data);for(const w of data.worlds){w.version=5;w.vault=w.communities[0].vault;for(const p of Object.values(w.players)){p.reload=Math.max(0,p.reload||0);p.hunger??=100;p.thirst??=100;}for(const b of w.walls){b.kind??="wall";b.maxHp??=180;}}data.version=5;}
  return data;
}

export function openStore(directory, now, mode='development') {
  mkdirSync(directory,{recursive:true});const path=directory+'/world.json';
  let data;
  if(existsSync(path)) {
    const raw=JSON.parse(readFileSync(path,'utf8'));
    // Preserve the exact previous file before changing any schema.
    if([1,2,3,4].includes(raw.version) && !existsSync(path+`.v${raw.version}.bak`))copyFileSync(path,path+`.v${raw.version}.bak`);
    data=migrate(raw);
  } else data={version:5,worlds:[createWorld(now,mode)],accounts:{}};
  return {data,save(){
    const tmp=path+'.tmp';writeFileSync(tmp,JSON.stringify(data));
    const fd=openSync(tmp,'r+');try{fsyncSync(fd);}finally{closeSync(fd);}
    renameSync(tmp,path);
  }};
}
