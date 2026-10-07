// Read-only capture of an existing saved mountain using the actual game scene.
import {spawn} from 'node:child_process';
import {readFileSync,writeFileSync,mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {migrate} from '../src/storage.mjs';
import {snapshot,createWorld,join as joinWorld} from '../src/world.mjs';
const engine=process.argv[2];
if(!engine)throw Error('Uso: node tools/capture-mountain.mjs RUTA_GODOT');
const data=migrate(JSON.parse(readFileSync(resolve('data-godot/world.json'),'utf8')));
let world=data.worlds.find(w=>w.communities.find(c=>c.id==='mountain').vault.hp>0&&Object.values(w.players).some(p=>p.communityId==='mountain'));
if(!world){world=createWorld();joinWorld(world,'mountain-preview','Guardia','mountain');}
const player=Object.values(world.players).find(p=>p.communityId==='mountain');
const directory=mkdtempSync(join(tmpdir(),'cerco-mountain-preview-'));
try {
 const stateFile=join(directory,'state.json');
 writeFileSync(stateFile,JSON.stringify(snapshot(world,player.id,new Set([player.id]))));
 const renderer=process.argv.includes('--forward')?['--rendering-method','forward_plus']:[];
 const child=spawn(engine,[...renderer,'--path',resolve('godot'),'--script','res://tests/mountain_preview.gd','--',`--snapshot=${stateFile}`],{stdio:['ignore','pipe','pipe'],windowsHide:true});
 let output='';
 for(const stream of [child.stdout,child.stderr])stream.on('data',chunk=>{output+=chunk;process.stdout.write(chunk);});
 const timer=setTimeout(()=>child.kill(),120000);
 const code=await new Promise((accept,reject)=>{child.once('exit',accept);child.once('error',reject);});
 clearTimeout(timer);
 if(code!==0||!output.includes('MOUNTAIN_PREVIEW_OK')||output.includes('SCRIPT ERROR')||output.includes('ERROR:'))process.exitCode=1;
}finally{rmSync(directory,{recursive:true,force:true});}
