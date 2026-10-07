import {spawn} from 'node:child_process';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {createServer} from '../server.mjs';
const directory=mkdtempSync(join(tmpdir(),'cerco-inventory-'));
const app=createServer({directory});
const initialized=new Set();
const seed=setInterval(()=>{
  for(const p of Object.values(app.world.players))if(!initialized.has(p.id)){
    initialized.add(p.id);
    Object.assign(p,{hp:45,hunger:40,thirst:40,food:3,water:3,medical:3,wood:130,materials:{reclaimed:70,timber:25,stone:20,scrap:10,components:5},weapons:['pistol','shotgun'],ammo:6,reserve:60});
  }
},10);
try{
  await new Promise(r=>app.server.listen(0,'127.0.0.1',r));
  const child=spawn(process.argv[2],['--path',resolve(process.argv[3]||'godot'),'--script','res://tests/inventory_smoke.gd','--',`--port=${app.server.address().port}`,`--profile=inventory_${Date.now()}`],{stdio:['ignore','pipe','pipe'],windowsHide:true});
  let output='';
  for(const s of [child.stdout,child.stderr])s.on('data',d=>{output+=d;process.stdout.write(d);});
  const timer=setTimeout(()=>child.kill(),30000);
  const code=await new Promise((r,j)=>{child.on('exit',r);child.on('error',j);});
  clearTimeout(timer);
  if(code!==0||!output.includes('INVENTORY_SMOKE failures=0')||output.includes('SCRIPT ERROR'))process.exitCode=1;
}finally{clearInterval(seed);await app.close();rmSync(directory,{recursive:true,force:true});}
