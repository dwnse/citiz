import {spawn} from 'node:child_process';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createServer} from '../server.mjs';
const engine=process.argv[2];
if(!engine)throw Error('Uso: node tools/verify-godot.mjs RUTA_GODOT [--capture]');
const directory=mkdtempSync(join(tmpdir(),'cerco-native-'));
const app=createServer({directory});
const w=app.world;
w.zombies=[[65,64],[67,69],[64,72]].map(([x,y],i)=>({id:'native-z'+i,x,y,hp:68,maxHp:68,level:1,attack:0,boss:false,communityId:'forest'}));
const capture=process.argv.includes('--capture');
const project=process.argv.find(arg=>arg.startsWith('--project='))?.slice(10)||'godot';
try{
  await new Promise(resolve=>app.server.listen(0,'127.0.0.1',resolve));
  const args=[...(capture?[]:['--headless']),'--path',fileURLToPath(new URL('../'+project+'/',import.meta.url)),'--script','res://tests/native_smoke.gd','--',`--port=${app.server.address().port}`,`--profile=smoke_${Date.now()}`,...(capture?['--capture']:[])];
  const child=spawn(engine,args,{stdio:['ignore','pipe','pipe'],windowsHide:true});
  let output='';
  for(const stream of [child.stdout,child.stderr])stream.on('data',chunk=>{output+=chunk;process.stdout.write(chunk);});
  const timeout=setTimeout(()=>child.kill(),45000);
  const code=await new Promise((resolve,reject)=>{child.on('error',reject);child.on('exit',resolve);});
  clearTimeout(timeout);
  if(code!==0||!output.includes('NATIVE_SMOKE failures=0')||output.includes('SCRIPT ERROR'))process.exitCode=1;
  else {
    app.save();
    const {openStore}=await import('../src/storage.mjs');
    const restored=openStore(directory,Date.now()).data.worlds[0];
    if(Object.keys(restored.players).length!==2||restored.walls.length!==5||restored.walls[0].level!==1)throw Error('Round-trip save mismatch');
    console.log('PASS native world saved and read back: 2 identities, 5 structures, upgrade');
  }
}finally{await app.close();rmSync(directory,{recursive:true,force:true});}
