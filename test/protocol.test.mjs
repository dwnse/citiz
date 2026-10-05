import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {createServer} from '../server.mjs';

test('contrato nativo anuncia protocolo y formato de guardado sin exponer identidades',async()=>{
  const directory=mkdtempSync(join(tmpdir(),'cerco-protocol-')),app=createServer({directory});
  try{
    await new Promise(resolve=>app.server.listen(0,'127.0.0.1',resolve));
    const response=await fetch(`http://127.0.0.1:${app.server.address().port}/api/protocol`);
    assert.equal(response.status,200);
    assert.deepEqual(await response.json(),{protocol:1,saveVersion:6,build:'0.14.0',features:['harvesting','vault-rebuild','adventure','typed-materials','patient-zero','boss-variants','population','workers','incidents','cosmetics'],transport:'http-sse',tickHz:30,snapshotHz:10,coordinates:'x,y -> Godot x,0,z'});
  }finally{await app.close();rmSync(directory,{recursive:true,force:true});}
});
