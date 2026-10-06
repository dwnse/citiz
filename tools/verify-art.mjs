import {spawn} from 'node:child_process';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {createServer} from '../server.mjs';
const engine=process.argv[2];
if(!engine)throw Error('Usage: node tools/verify-art.mjs GODOT [--capture] [--project=godot]');
const directory=mkdtempSync(join(tmpdir(),'cerco-art-'));
const app=createServer({directory});
const w=app.world;
w.zombies=[];
const configured=new Set();
let staged=false, killer=false;
// Controlled combat fixture; never reads or writes the user's saved world.
const fixture=setInterval(()=>{
  for(const p of Object.values(w.players))if(!configured.has(p.id)){
    configured.add(p.id);p.x=p.name==='Art A'?44:39;p.y=65;p.hp=p.name==='Art A'?18:100;p.armor=0;
  }
  if(configured.size===2&&!staged){
    staged=true;
    w.zombies.push({id:'art-common',x:66,y:65,hp:56,maxHp:56,attack:0,level:1,communityId:'forest',variant:'walker'});
  }
  if(staged&&!killer&&w.fallen?.some(z=>z.id==='art-common')){
    killer=true;
    const p=Object.values(w.players).find(p=>p.name==='Art A');
    w.zombies.push({id:'art-contact',x:p.x+1.9,y:p.y,hp:999,maxHp:999,attack:0,level:1,communityId:'forest',variant:'walker'});
  }
},10);
try{
  await new Promise(resolve=>app.server.listen(0,'127.0.0.1',resolve));
  const project=process.argv.find(a=>a.startsWith('--project='))?.slice(10)||'godot';
  const capture=process.argv.includes('--capture');
  const args=[...(capture?[]:['--headless']),'--path',resolve(project),'--script','res://tests/art_smoke.gd','--',`--port=${app.server.address().port}`,`--profile=art_${Date.now()}`,...(capture?['--capture']:[])];
  const child=spawn(engine,args,{stdio:['ignore','pipe','pipe'],windowsHide:true});
  let output='';
  for(const stream of [child.stdout,child.stderr])stream.on('data',chunk=>{output+=chunk;process.stdout.write(chunk);});
  const timeout=setTimeout(()=>child.kill(),50000);
  const code=await new Promise((resolve,reject)=>{child.on('error',reject);child.on('exit',resolve);});
  clearTimeout(timeout);
  if(code!==0||!output.includes('ART_SMOKE failures=0')||output.includes('SCRIPT ERROR'))process.exitCode=1;
}finally{clearInterval(fixture);await app.close();rmSync(directory,{recursive:true,force:true});}
