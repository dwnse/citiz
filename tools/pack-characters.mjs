// Repackage Quaternius' self-contained glTF as GLB without changing geometry/rig.
import fs from 'node:fs';
const output = 'godot/assets/characters';
fs.mkdirSync(output, {recursive:true});
for (const name of ['Sam','Zombie']) {
  const source = fs.readFileSync(`assets-source/characters/${name}.gltf`);
  const json = JSON.parse(source);
  if (json.buffers.length !== 1 || !json.buffers[0].uri.startsWith('data:')) throw Error('Expected embedded single buffer');
  const binary = Buffer.from(json.buffers[0].uri.split(',')[1], 'base64');
  delete json.buffers[0].uri;
  const raw = Buffer.from(JSON.stringify(json));
  const metadata = Buffer.alloc(Math.ceil(raw.length/4)*4, 32); raw.copy(metadata);
  const bin = Buffer.alloc(Math.ceil(binary.length/4)*4); binary.copy(bin);
  const header = Buffer.alloc(12); header.writeUInt32LE(0x46546c67); header.writeUInt32LE(2,4); header.writeUInt32LE(28+metadata.length+bin.length,8);
  const chunk = (length,type) => {const b=Buffer.alloc(8); b.writeUInt32LE(length); b.writeUInt32LE(type,4); return b;};
  fs.writeFileSync(`${output}/${name}.glb`, Buffer.concat([header,chunk(metadata.length,0x4e4f534a),metadata,chunk(bin.length,0x004e4942),bin]));
  console.log(name, json.animations?.length ?? 0, 'animations', binary.length, 'bytes');
}
