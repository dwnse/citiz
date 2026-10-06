import {spawn} from 'node:child_process';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {createServer} from '../server.mjs';
const engine=process.argv[2];
if(!engine)throw Error('Usage: node tools/capture-art.mjs GODOT [--compare] [--before]');
const directory=mkdtempSync(join(tmpdir(),'cerco-art-capture-'));
const app=createServer({directory});
try{
  await new Promise(resolve=>app.server.listen(0,'127.0.0.1',resolve));
  const compare=process.argv.includes('--compare');
  const args=['--path',resolve('godot'),'--script',compare?'res://tests/art_comparison.gd':'res://tests/art_showcase.gd',...(!compare?['--write-movie',resolve('docs/art-021-animations.avi'),'--fixed-fps','30']:[]),'--',`--port=${app.server.address().port}`,`--profile=art_capture_${Date.now()}`,...(process.argv.includes('--before')?['--before']:[])];
  const child=spawn(engine,args,{stdio:['ignore','pipe','pipe'],windowsHide:true});
  let output='';
  for(const stream of [child.stdout,child.stderr])stream.on('data',chunk=>{output+=chunk;process.stdout.write(chunk);});
  const timeout=setTimeout(()=>child.kill(),45000);
  const code=await new Promise((resolve,reject)=>{child.on('error',reject);child.on('exit',resolve);});
  clearTimeout(timeout);
  if(code!==0||output.includes('SCRIPT ERROR')||output.includes('ERROR:'))process.exitCode=1;
}finally{await app.close();rmSync(directory,{recursive:true,force:true});}
