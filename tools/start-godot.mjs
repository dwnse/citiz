// Separate, persistent training world. Never opens data/ or data-demostracion/.
import {createServer} from '../server.mjs';
import {randomUUID} from 'node:crypto';
import {fileURLToPath} from 'node:url';
// Check before opening saves: an old server may still be writing the same directory.
let running=null;
try{const response=await fetch('http://127.0.0.1:3002/api/protocol',{signal:AbortSignal.timeout(1000)});running=await response.json();}catch{}
if(running){
  console.log(running.build==='0.20.0'?'El Cerco 0.20 ya está activo en el puerto 3002. Abre Godot.':'Hay un servidor anterior en el puerto 3002. Cierra SU consola con Ctrl+C y vuelve a ejecutar node tools/start-godot.mjs. No se han abierto ni modificado los guardados.');
  process.exit(running.build==='0.20.0'?0:1);
}
const app=createServer({directory:fileURLToPath(new URL('../data-godot/',import.meta.url))});
const timer=setInterval(()=>{
  const w=app.world;
  if(w.godotTrainingSeeded||!Object.keys(w.players).length)return;
  w.godotTrainingSeeded=true;
  for(const [x,y] of [[42,55],[45,55],[55,55],[58,55]])w.walls.push({id:randomUUID(),communityId:'forest',x,y,rot:0,hp:180,maxHp:180});
  for(const [x,y] of [[39,70],[58,71],[64,62]])w.zombies.push({id:randomUUID(),communityId:'forest',x,y,hp:68,maxHp:68,level:1,attack:0,boss:false});
  w.nextWave=Date.now()+35000;app.save();
},100);
app.server.listen(3002,'127.0.0.1',()=>console.log('El Cerco 0.16: http://127.0.0.1:3002 · data-godot/'));
for(const signal of ['SIGINT','SIGTERM'])process.on(signal,async()=>{clearInterval(timer);await app.close();process.exit(0);});
