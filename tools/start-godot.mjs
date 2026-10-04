// Separate, persistent training world. Never opens data/ or data-demostracion/.
import {createServer} from '../server.mjs';
import {randomUUID} from 'node:crypto';
import {fileURLToPath} from 'node:url';
const app=createServer({directory:fileURLToPath(new URL('../data-godot/',import.meta.url))});
const timer=setInterval(()=>{
  const w=app.world;
  if(w.godotTrainingSeeded||!Object.keys(w.players).length)return;
  w.godotTrainingSeeded=true;
  for(const [x,y] of [[42,55],[45,55],[55,55],[58,55]])w.walls.push({id:randomUUID(),communityId:'forest',x,y,rot:0,hp:180,maxHp:180});
  for(const [x,y] of [[39,70],[58,71],[64,62]])w.zombies.push({id:randomUUID(),communityId:'forest',x,y,hp:68,maxHp:68,level:1,attack:0,boss:false});
  w.nextWave=Date.now()+95000;app.save();
},100);
app.server.listen(3002,'127.0.0.1',()=>console.log('Godot training: http://127.0.0.1:3002 · data-godot/'));
for(const signal of ['SIGINT','SIGTERM'])process.on(signal,async()=>{clearInterval(timer);await app.close();process.exit(0);});
