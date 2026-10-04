const $=id=>document.getElementById(id),canvas=$('game'),ctx=canvas.getContext('2d');
let W=innerWidth,H=innerHeight,dpr=1,state=null,id=null,seq=0,build=false,rot=0,mouse={x:W/2,y:H/2},keys=new Set(),held=false,connected=false,cam={x:50,y:52},last=performance.now(),fps=60,latency=0,audio,shotAt=0;
function resize(){W=innerWidth;H=innerHeight;dpr=Math.min(devicePixelRatio,2);canvas.width=W*dpr;canvas.height=H*dpr;ctx.setTransform(dpr,0,0,dpr,0,0);}addEventListener('resize',resize);resize();
const scale=22;
function project(x,y,z=0){return {x:W/2+(x-cam.x-y+cam.y)*scale,y:H/2+(x-cam.x+y-cam.y)*scale*.52-z*scale};}
function ground(x,y){const a=(x-W/2)/scale,b=(y-H/2)/(scale*.52);return{x:cam.x+(a+b)/2,y:cam.y+(b-a)/2};}
function poly(points,color,stroke){ctx.beginPath();points.forEach((p,i)=>i?ctx.lineTo(p.x,p.y):ctx.moveTo(p.x,p.y));ctx.closePath();ctx.fillStyle=color;ctx.fill();if(stroke){ctx.strokeStyle=stroke;ctx.stroke();}}
function tile(x,y,s,color){poly([project(x-s,y-s),project(x+s,y-s),project(x+s,y+s),project(x-s,y+s)],color);}
function box(x,y,sx,sy,h,colors,base=0){const a=project(x-sx,y-sy,base),b=project(x+sx,y-sy,base),c=project(x+sx,y+sy,base),d=project(x-sx,y+sy,base),aa=project(x-sx,y-sy,h),bb=project(x+sx,y-sy,h),cc=project(x+sx,y+sy,h),dd=project(x-sx,y+sy,h);poly([b,c,cc,bb],colors[1]);poly([c,d,dd,cc],colors[2]);poly([aa,bb,cc,dd],colors[0]);}
function circle(x,y,r,color,stroke){const p=project(x,y);ctx.beginPath();ctx.ellipse(p.x,p.y,r*scale*1.414,r*scale*.735,0,0,Math.PI*2);if(color){ctx.fillStyle=color;ctx.fill();}if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=2;ctx.stroke();}}
function text(x,y,z,label,color='#dbe9cd'){const p=project(x,y,z);ctx.font='10px Segoe UI';ctx.textAlign='center';ctx.fillStyle='#07100bd9';ctx.fillRect(p.x-ctx.measureText(label).width/2-6,p.y-11,ctx.measureText(label).width+12,16);ctx.fillStyle=color;ctx.fillText(label,p.x,p.y);}
function person(p,zombie=false){circle(p.x,p.y,.65,'#0005');if(!zombie)circle(p.x,p.y,.8,null,state?.communities.find(c=>c.id===p.communityId)?.color||'#c6e78a');const boss=p.boss,f=boss?1.65:1;box(p.x-.16,p.y,.14,.19,.48*f,['#344347','#1b292a','#192327']);box(p.x+.2,p.y,.14,.19,.48*f,['#344347','#1b292a','#192327']);box(p.x,p.y,.36*f,.26*f,1.12*f,zombie?['#82955c','#4b654a','#3a5040']:['#a4b9a9','#577d71','#3c5b57'],.48*f);box(p.x,p.y,.23*f,.22*f,1.6*f,zombie?['#bfbc81','#7a8765','#647356']:['#dcc8a0','#ac997a','#8d846e'],1.15*f);if(!zombie){const a=p.angle||0;const h=project(p.x,p.y,1),end=project(p.x+Math.cos(a)*1.05,p.y+Math.sin(a)*1.05,1);ctx.strokeStyle='#bcc5b7';ctx.lineWidth=5;ctx.beginPath();ctx.moveTo(h.x,h.y);ctx.lineTo(end.x,end.y);ctx.stroke();text(p.x,p.y,2,p.name,p.id===id?'#d4ee99':'#a8dbe0');}else if(p.hp<p.maxHp||boss){const s=project(p.x,p.y,2.1*f);ctx.fillStyle='#1b2520';ctx.fillRect(s.x-18,s.y,36,3);ctx.fillStyle=boss?'#e3a27c':'#a8be77';ctx.fillRect(s.x-18,s.y,36*p.hp/p.maxHp,3);}}
function tree(x,y,n){circle(x,y,1.5,'#06171166');box(x,y,.2,.2,1.7,['#6a6750','#393d31','#303d30']);for(let i=0;i<3;i++){const p=project(x,y,2+i*.9);ctx.beginPath();ctx.moveTo(p.x,p.y-42+i*5);ctx.lineTo(p.x+30-i*6,p.y+15);ctx.lineTo(p.x-30+i*6,p.y+15);ctx.closePath();ctx.fillStyle=['#254638','#315640','#3b6247'][(n+i)%3];ctx.fill();}}
let treeWorld=null,trees=[];
function prepareTrees(){const key=state?.id||'preview';if(key===treeWorld)return;treeWorld=key;trees=[];
  for(const c of state?.communities||[{id:'forest',x:50,y:50}]){
    const count=c.id==='mountain'?180:c.id==='forest'?100:15;
    for(let i=0;i<count;i++){const x=c.x-45+(i*37.17)%90,y=c.y-45+(i*19.73)%90;if(Math.hypot(x-c.x,y-c.y)>22&&Math.abs(x-c.x)>5&&Math.abs(y-105)>5)trees.push({x,y,n:i});}
  }
}
function render(now){const dt=Math.min(.1,(now-last)/1000);last=now;fps=fps*.94+1/Math.max(dt,.001)*.06;const me=state?.players.find(p=>p.id===id);if(me){cam.x+=(me.x-cam.x)*Math.min(1,dt*8);cam.y+=(me.y-cam.y)*Math.min(1,dt*8);}
ctx.clearRect(0,0,W,H);ctx.fillStyle='#12251f';ctx.fillRect(0,0,W,H);
const size=state?.size||100,communities=state?.communities||[{id:'forest',x:50,y:50,color:'#c6e78a',ground:'#294335',name:'BÓVEDA / REFUGIO',vault:{x:50,y:50,hp:1500}}];
const corners=[ground(0,0),ground(W,0),ground(0,H),ground(W,H)];
const minX=Math.max(0,Math.floor(Math.min(...corners.map(p=>p.x))/4)*4-4),maxX=Math.min(size,Math.max(...corners.map(p=>p.x))+4),minY=Math.max(0,Math.floor(Math.min(...corners.map(p=>p.y))/4)*4-4),maxY=Math.min(size,Math.max(...corners.map(p=>p.y))+4);
for(let x=minX;x<maxX;x+=4)for(let y=minY;y<maxY;y+=4){const region=communities.find(c=>(c.x>105)===(x>105)&&(c.y>105)===(y>105))||communities[0];tile(x+2,y+2,2,region.ground);if(Math.sin(x*13+y*7)>.7)tile(x+2,y+2,2,'#a1b59806');}
for(const c of communities){poly([project(c.x-3,0),project(c.x+3,0),project(c.x+3,size),project(c.x-3,size)],'#585647');circle(c.x,c.y,18+(c.vault.upgrades||0)*6,null,c.color+'55');circle(c.x,c.y,4,'#98b87913',c.color+'88');}
if(size>100)poly([project(0,102),project(size,102),project(size,108),project(0,108)],'#585647');
prepareTrees();
const objects=trees.map(t=>({...t,draw:()=>tree(t.x,t.y,t.n)}));
for(const b of state?.obstacles||[])objects.push({...b,draw:()=>{box(b.x,b.y,b.sx,b.sy,1.3,['#829080','#4e6255','#3b5147']);box(b.x-.3,b.y,.65,.7,1.9,['#8a9582','#647464','#56685a'],1.3);}});
for(const c of communities){const v=c.vault;objects.push({...v,draw:()=>{box(v.x,v.y,2,2,.5,['#6b7970','#405449','#34453f']);box(v.x,v.y,1,1,2.6,v.hp>0?[c.color,'#598a77','#446d60']:['#69675d','#434640','#343b35']);const p=project(v.x,v.y,3.2);const glow=ctx.createRadialGradient(p.x,p.y,2,p.x,p.y,65);glow.addColorStop(0,v.hp>0?c.color+'88':'#cc685533');glow.addColorStop(1,'#afff9000');ctx.fillStyle=glow;ctx.fillRect(p.x-65,p.y-65,130,130);text(v.x,v.y,4,v.hp>0?c.name:'BÓVEDA DESTRUIDA',c.color);}});}
for(const b of state?.walls||[])objects.push({...b,draw:()=>{const d=state.buildingCatalog?.find(d=>d.id===(b.kind||'wall'))||{name:'Muro',width:3.2,depth:1.2,height:2.4,hp:180};if(b.kind==='gate'&&b.open)circle(b.x,b.y,1.4,null,'#9dd698');else box(b.x,b.y,(b.rot?d.depth:d.width)/2,(b.rot?d.width:d.depth)/2,d.height,['#b7a781','#726b51','#605d49']);if(b.kind&&b.kind!=='wall')text(b.x,b.y,d.height+.6,d.name+(b.open?' · ABIERTO':'')+(b.stock!=null?' · '+b.stock:''),'#dfc48c');if(b.hp<(b.maxHp||d.hp))text(b.x,b.y,d.height+.2,Math.ceil(b.hp)+' / '+(b.maxHp||d.hp),'#dfc48c');}});
for(const d of state?.drops||[])objects.push({...d,draw:()=>{box(d.x,d.y,.35,.35,.5,['#d5b977','#8f835b','#6d7151']);circle(d.x,d.y,.7,null,'#d9c78b55');}});
if(state?.story){
  const radio=state.story.radio;
  objects.push({...radio,draw:()=>{box(radio.x,radio.y,1.4,.7,.5,['#8c8c72','#444f4a','#303e39']);box(radio.x+.5,radio.y,.35,.35,1.1,['#adc1b0','#5d7165','#3e574a'],.5);if(!state.story.prologue)text(radio.x,radio.y,1.7,'E · RECUPERAR RADIO','#e2d19a');}});
  for(const mage of state.story.mages){objects.push({...mage,draw:()=>{circle(mage.x,mage.y,1,'#bda7ea22','#bfa9ed');box(mage.x,mage.y,.35,.3,1.3,['#c4a9df','#77618e','#59486c']);box(mage.x,mage.y,.22,.22,1.7,['#e1d5bd','#b5a58d','#8a7d6c'],1.3);text(mage.x,mage.y,2.3,mage.name+' · E',mage.id===trackedMage?'#fff1b1':'#dec2f4');}});}
  if(state.story.prologue>=2){const seal=state.story.seal;objects.push({...seal,draw:()=>{circle(seal.x,seal.y,3,'#704e8b55','#c1a8ef');box(seal.x,seal.y,1.1,1.1,.6,['#aaa0bb','#605473','#443854']);text(seal.x,seal.y,2,state.story.opened?'ENCIERRO ABIERTO':'SELLO · SEIS CLAVES','#dfc5f2');}});}
}
for(const p of state?.players||[])if(p.alive&&p.online)objects.push({...p,draw:()=>person(p)});
for(const z of state?.zombies||[]){if(z.warning>0)circle(z.x,z.y,6,'#db685233','#ed9474');objects.push({...z,draw:()=>person(z,true)});}
objects.sort((a,b)=>a.x+a.y-b.x-b.y);for(const o of objects){const p=project(o.x,o.y);if(p.x> -100&&p.x<W+100&&p.y> -100&&p.y<H+180)o.draw();}
for(const s of state?.shots||[]){const a=project(s.x,s.y,1),b=project(s.x+Math.cos(s.angle)*s.length,s.y+Math.sin(s.angle)*s.length,.8);ctx.beginPath();ctx.strokeStyle='#ffe7aa';ctx.lineWidth=2;ctx.moveTo(a.x,a.y);ctx.lineTo(b.x,b.y);ctx.stroke();}
for(const f of state?.effects||[])circle(f.x,f.y,1+(1-f.life/.7)*4,null,f.power==='heal'?'#cceca0':f.power==='control'?'#dda5ee':'#a8d8ee');
for(const p of state?.players||[])if(p.alive&&p.magic?.effects.shield>Date.now()&&p.magic.shieldHp>0)circle(p.x,p.y,1.4,'#a0dbec22','#acdced');
for(const z of state?.zombies||[])if(z.charmUntil>Date.now())circle(z.x,z.y,1.1,null,'#cc99ee');
if(build&&me){const g=ground(mouse.x,mouse.y),x=Math.round(g.x),y=Math.round(g.y),valid=validBuild(me,x,y);ctx.globalAlpha=.6;box(x,y,rot?.5:1.5,rot?1.5:.5,1.6,valid?['#d0f59d','#96c97f','#6cad75']:['#f59779','#d26e61','#a9524b']);ctx.globalAlpha=1;}
if(me){updateHud(me);updateStoryHud(me);if(held&&!build&&connected&&now-shotAt>260&&!$('guide').open&&!$('journal').open){shotAt=now;act('shoot',{angle:aim(me)}).then(ok=>{if(ok)beep();});}}
requestAnimationFrame(render);}
function validBuild(p,x,y){const v=state.vault;return p.alive&&p.wood>=20&&v.hp>0&&state.walls.filter(b=>b.communityId===p.communityId).length<80&&Math.hypot(x-v.x,y-v.y)<18+(v.upgrades||0)*6&&Math.hypot(x-v.x,y-v.y)>4&&Math.hypot(x-p.x,y-p.y)<9&&Math.abs(x-50)>=3&&(state.legacy||(Math.abs(x-160)>=3&&Math.abs(y-105)>=3))&&!(state.obstacles||[]).some(b=>Math.abs(b.x-x)<b.sx+2&&Math.abs(b.y-y)<b.sy+2)&&!state.walls.some(b=>Math.abs(b.x-x)<2.5&&Math.abs(b.y-y)<2.5)&&!state.players.some(q=>q.alive&&Math.hypot(q.x-x,q.y-y)<2);}
function aim(p){const g=ground(mouse.x,mouse.y);return Math.atan2(g.y-p.y,g.x-p.x);}
function beep(){try{audio||=new AudioContext();const o=audio.createOscillator(),g=audio.createGain();o.type='triangle';o.frequency.setValueAtTime(130,audio.currentTime);o.frequency.exponentialRampToValueAtTime(45,audio.currentTime+.07);g.gain.setValueAtTime(.08,audio.currentTime);g.gain.exponentialRampToValueAtTime(.001,audio.currentTime+.09);o.connect(g);g.connect(audio.destination);o.start();o.stop(audio.currentTime+.1);}catch{}}
function updateHud(p){$('agentName').textContent=p.name.toUpperCase();$('hpText').textContent=Math.ceil(p.hp)+' PV';$('hpBar').style.width=p.hp+'%';$('armor').textContent='BLINDAJE '+Math.ceil(p.armor)+' · COMIDA '+Math.floor(p.hunger??100)+' · AGUA '+Math.floor(p.thirst??100);$('ammo').textContent=p.reload>0?'…':p.ammo;$('reserve').textContent='/ '+p.reserve;$('wood').textContent=p.wood+' MATERIALES';$('vaultText').textContent=state.vault.hp+' / 1500';$('vaultBar').style.width=state.vault.hp/15+'%';const remain=Math.max(0,Math.ceil((state.nextWave-Date.now())/1000));$('countdown').textContent=String(Math.floor(remain/60)).padStart(2,'0')+':'+String(remain%60).padStart(2,'0');$('waveTitle').textContent=state.wave?'Oleada '+state.wave:'Sin contacto';$('waveSub').textContent=state.zombies.length?state.zombies.length+' INFECTADOS EN EL SECTOR':'PREPARA LAS DEFENSAS';$('notice').textContent=state.events.at(-1)?.text||'';$('objective').textContent=p.intro?'Construye muros, recoge suministros y defiende la bóveda.':'El transporte cayó. Camina hacia la luz de la bóveda y pulsa E para estabilizarla.';if(state.phase!=='active')$('toast').textContent=state.phase==='defeat'?'COMUNIDAD ELIMINADA · El refugio ha caído.':'EL SELLO HA CEDIDO · Mundo terminado.';else if(!p.alive)$('toast').textContent=state.vault.hp>0?'HAS CAÍDO · Reaparición en '+Math.max(0,Math.ceil((p.respawn-Date.now())/1000))+' s':'HAS CAÍDO · No quedan reapariciones.';else if($('toast').textContent.startsWith('HAS CAÍDO'))$('toast').textContent='';}
async function post(url,data){const start=performance.now();const r=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({...data,...(state?{worldId:state.id}:{})})});latency=performance.now()-start;const v=await r.json();if(!r.ok)throw Error(v.error);return v;}
async function act(type,data={}){if(!connected)return false;try{const v=await post('/api/action',{type,seq:++seq,...data});if(!v.ok&&type!=='shoot')toast('Acción no disponible: revisa materiales, distancia y ubicación.');return v.ok;}catch(e){toast(e.message);return false;}}
let toastTimer;function toast(t){$('toast').textContent=t;clearTimeout(toastTimer);toastTimer=setTimeout(()=>{$('toast').textContent='';},2500);}
let directory=[],stream=null,reconnectTimer=null;
let trackedMage=null;
function worldInfo(){const w=directory.find(w=>w.id===$('worldSelect').value);if(!w)return;$('worldInfo').textContent=`${w.members}/${w.capacity} inscritos · ${w.online} conectados · ${Math.ceil(w.remaining/86400000)} días restantes · ${w.phase==='active'?'ABIERTO':'CERRADO'}`;
  const previous=$('communitySelect').value;$('communitySelect').replaceChildren();
  for(const c of w.communities||[]){const option=document.createElement('option');option.value=c.id;option.textContent=`${c.region} · ${c.name} · ${c.members}/10${c.eliminated?' · ELIMINADA':!c.vaultAlive?' · SIN BÓVEDA':''}`;option.disabled=c.members>=10||c.eliminated||!c.vaultAlive;$('communitySelect').append(option);}
  if([...$('communitySelect').options].some(o=>o.value===previous&&!o.disabled))$('communitySelect').value=previous;
  $('communitySelect').disabled=!!localStorage.getItem('cerco-key:'+w.id);
  const known=localStorage.getItem('cerco-community:'+w.id);if(known)$('communitySelect').value=known;
}
async function refreshWorlds(selected){
  try{const data=await fetch('/api/worlds').then(r=>r.json());directory=data.worlds;
    const legacy=localStorage.getItem('cerco-key');if(legacy&&directory[0]){localStorage.setItem('cerco-key:'+directory[0].id,legacy);localStorage.removeItem('cerco-key');}
    const previous=selected||$('worldSelect').value; $('worldSelect').replaceChildren();
    for(const w of directory){const option=document.createElement('option');option.value=w.id;option.textContent=w.name+' · '+w.members+'/'+w.capacity+(w.phase==='active'?'':' · TERMINADA');$('worldSelect').append(option);}
    if(directory.some(w=>w.id===previous))$('worldSelect').value=previous;
    $('newWorld').hidden=data.mode!=='development';$('newWorld').disabled=directory.length>=8;worldInfo();
  }catch(e){$('error').textContent='No se pudo cargar la sala: '+e.message;}
}
function leave(){stream?.close();stream=null;clearTimeout(reconnectTimer);connected=false;held=false;keys.clear();state=null;id=null;toggleBuild(false);$('lobby').hidden=false;$('hud').hidden=true;$('enter').disabled=false;$('connection').textContent='SIN CONEXIÓN';refreshWorlds();}
$('leave').onclick=leave;
$('worldSelect').onchange=worldInfo;$('refreshWorlds').onclick=()=>refreshWorlds();
$('newWorld').onclick=async()=>{try{$('newWorld').disabled=true;const r=await post('/api/worlds',{name:'Cerco '+(directory.length+1)});await refreshWorlds(r.world.id);$('error').textContent='';}catch(e){$('error').textContent=e.message;$('newWorld').disabled=false;}};
$('enter').onclick=async()=>{
  try{$('enter').disabled=true;const worldId=$('worldSelect').value;
    const joined=await post('/api/join',{worldId,communityId:$('communitySelect').value,name:$('name').value,key:localStorage.getItem('cerco-key:'+worldId)||undefined});id=joined.id;seq=joined.seq;
    localStorage.setItem('cerco-key:'+joined.worldId,joined.key);localStorage.setItem('cerco-community:'+joined.worldId,joined.communityId);stream?.close();stream=new EventSource('/api/events?worldId='+encodeURIComponent(joined.worldId));
    stream.onmessage=e=>{clearTimeout(reconnectTimer);reconnectTimer=null;state=JSON.parse(e.data);connected=true;$('connection').textContent='EN LÍNEA';};
    stream.onerror=()=>{connected=false;held=false;$('connection').textContent='RECONECTANDO';if(!reconnectTimer)reconnectTimer=setTimeout(()=>{leave();$('error').textContent='Conexión interrumpida. Vuelve a entrar para recuperar tu agente.';},5000);};
    $('error').textContent='';$('lobby').hidden=true;$('hud').hidden=false;audio||=new AudioContext();
  }catch(e){$('error').textContent=e.message;$('enter').disabled=false;}
};
refreshWorlds();
function toggleBuild(value=!build){build=value;$('buildHint').hidden=!build;$('weaponSlot').classList.toggle('selected',!build);$('buildSlot').classList.toggle('selected',build);}
function help(){if($('guide').open)$('guide').close();else{if($('journal').open)$('journal').close();$('guide').showModal();keys.clear();held=false;}}$('help').onclick=help;$('closeHelp').onclick=help;
addEventListener('keydown',e=>{if(e.target.tagName==='INPUT')return;if(['ArrowUp','ArrowDown','ArrowLeft','ArrowRight',' '].includes(e.key))e.preventDefault();keys.add(e.key.toLowerCase());if(e.repeat)return;if(e.key.toLowerCase()==='h')help();if($('guide').open||$('journal').open)return;const p=state?.players.find(p=>p.id===id);if(!p)return;switch(e.key.toLowerCase()){case 'b':toggleBuild();break;case '1':case 'escape':toggleBuild(false);break;case 'g':rot=1-rot;break;case 'r':act('reload');break;case 'c':act('craft');break;case 'e':act('interact');break;case 'f':case 'x':{const b=[...state.walls.filter(b=>b.communityId===p.communityId)].sort((a,b)=>Math.hypot(a.x-p.x,a.y-p.y)-Math.hypot(b.x-p.x,b.y-p.y))[0];if(b)act(e.key.toLowerCase()==='f'?'repair':'dismantle',{id:b.id});break;}}});
addEventListener('keyup',e=>keys.delete(e.key.toLowerCase()));addEventListener('blur',()=>{keys.clear();held=false;});
canvas.addEventListener('mousemove',e=>{mouse={x:e.clientX,y:e.clientY};$('crosshair').style.left=mouse.x+'px';$('crosshair').style.top=mouse.y+'px';});
canvas.addEventListener('mousedown',e=>{if(e.button!==0)return;held=true;if(build){const g=ground(mouse.x,mouse.y);act('build',{x:Math.round(g.x),y:Math.round(g.y),rot});}});addEventListener('mouseup',()=>held=false);
let inputBusy=false;setInterval(async()=>{const p=state?.players.find(p=>p.id===id);if(!p||!connected||inputBusy)return;const sx=(keys.has('d')||keys.has('arrowright')?1:0)-(keys.has('a')||keys.has('arrowleft')?1:0),sy=(keys.has('s')||keys.has('arrowdown')?1:0)-(keys.has('w')||keys.has('arrowup')?1:0);inputBusy=true;try{await post('/api/input',{x:($('guide').open||$('journal').open)?0:(sx+sy)*.7071,y:($('guide').open||$('journal').open)?0:(sy-sx)*.7071,angle:aim(p)});}catch{}finally{inputBusy=false;}},65);
setInterval(()=>{if(connected)$('metrics').textContent=Math.round(fps)+' FPS · '+Math.round(latency)+' MS · '+state.connectedCount+' AGENTES';},1000);
requestAnimationFrame(render);

function updateStoryHud(p){
  const story=state.story;if(!story)return;
  if(story.message?.until>Date.now())$('notice').textContent=story.message.text;
  if(story.prologue===0)$('objective').textContent='E: recuperar la radio del transporte. La última orden era investigar la ciudad.';
  else if(!p.intro)$('objective').textContent='Camina hasta tu bóveda y pulsa E. Busca refugio tras la anomalía.';
  else if(story.opened)$('objective').textContent='Encierro abierto para tu comunidad. El encuentro con el Paciente 0 está pendiente de la siguiente etapa.';
  else if(story.fragments.length===6)$('objective').textContent=`Seis claves reunidas. Ve al sello (${story.seal.x}, ${story.seal.y}) y pulsa E.`;
  else {
    let target=story.mages.find(m=>m.id===trackedMage);
    if(!target||p.magic.known.includes(target.power))target=[...story.mages].filter(m=>!p.magic.known.includes(m.power)).sort((a,b)=>Math.hypot(a.x-p.x,a.y-p.y)-Math.hypot(b.x-p.x,b.y-p.y))[0];
    if(target){trackedMage=target.id;$('objective').textContent=`${target.name}: ${Math.round(Math.hypot(target.x-p.x,target.y-p.y))} m · (${Math.round(target.x)}, ${Math.round(target.y)}). E para hablar. J: pistas · ${story.fragments.length}/6 claves.`;}
  }
}
function updateJournal(){
  if(!state?.story)return;const p=state.players.find(p=>p.id===id),story=state.story;
  $('journalMessage').textContent=story.message?.text||(!p.intro?'Recupera la radio con E y alcanza la bóveda antes de buscar señales.':'Cada señal pertenece a un mago. Sus recorridos siguen corredores públicos y las pistas se actualizan al moverse.');
  $('mageList').replaceChildren();
  for(const mage of story.mages){const spell=story.spells.find(s=>s.id===mage.power),button=document.createElement('button');button.textContent=`${mage.name} · ${spell.name}${p.magic.known.includes(mage.power)?' ✓':''}\nSeñal: ${Math.round(mage.x)}, ${Math.round(mage.y)} · ${Math.round(Math.hypot(mage.x-p.x,mage.y-p.y))} m. ${spell.description}`;button.onclick=()=>{trackedMage=mage.id;$('journal').close();};$('mageList').append(button);}
  $('chapterList').replaceChildren();for(const fragment of story.fragments){const paragraph=document.createElement('p');paragraph.textContent=fragment.text;$('chapterList').append(paragraph);}
  $('sealStatus').textContent=story.opened?'Acceso abierto. Jefe final aún no implementado.':`${story.fragments.length}/6 claves comunitarias. Las seis abren el encierro (${story.seal.x}, ${story.seal.y}). Los poderes se aprenden individualmente y no se agotan para otros jugadores.`;
}
function journal(){if($('journal').open)$('journal').close();else if(state){if($('guide').open)$('guide').close();keys.clear();held=false;updateJournal();$('journal').showModal();}}
$('journalButton').onclick=journal;$('closeJournal').onclick=journal;
addEventListener('keydown',e=>{
  if(e.target.tagName==='INPUT'||e.repeat)return;
  if(e.key.toLowerCase()==='j'){journal();return;}
  if(!$('guide').open&&!$('journal').open){const spell=state?.story?.spells.find(s=>s.key===e.key);if(spell)act('cast',{power:spell.id});}
});
setInterval(()=>{
  if(!state?.story)return;const p=state.players.find(p=>p.id===id),magic=p.magic,story=state.story;
  $('magicHud').hidden=!magic?.known.length;
  if(!$('magicHud').hidden){
    $('manaText').textContent=`ENERGÍA ${Math.floor(magic.mana)} / 100 · Regenera 4 por segundo`;
    if($('magicButtons').children.length!==story.spells.length){$('magicButtons').replaceChildren();for(const spell of story.spells){const button=document.createElement('button');button.id='spell-'+spell.id;button.onclick=()=>act('cast',{power:spell.id});button.title=`${spell.description} Coste: ${spell.cost}`;$('magicButtons').append(button);}}
    for(const spell of story.spells){const button=$('spell-'+spell.id),cooldown=Math.max(0,Math.ceil(((magic.cooldowns[spell.id]||0)-Date.now())/1000));button.disabled=!p.alive||!magic.known.includes(spell.id)||magic.mana<spell.cost||cooldown>0;button.textContent=`${spell.key} ${spell.name}${cooldown?' '+cooldown+'s':''}`;}
  }

},500);

const mapContext=$('mapCanvas').getContext('2d');
setInterval(()=>{
  if(!state)return;
  const own=state.communities.find(c=>c.id===state.communityId),s=state.siege;
  const player=state.players.find(p=>p.id===id),region=[...state.communities].sort((a,b)=>Math.hypot(a.x-player.x,a.y-player.y)-Math.hypot(b.x-player.x,b.y-player.y))[0];
  $('regionLabel').textContent=region.region.toUpperCase();
  const seconds=Math.max(0,Math.ceil((s?.remaining||0)/1000)),clock=String(Math.floor(seconds/60)).padStart(2,'0')+':'+String(seconds%60).padStart(2,'0');
  $('siege').textContent=s?.enabled?`${s.active?'ASEDIO ACTIVO':'PRÓXIMO ASEDIO'} · ${clock} · Requiere defensores conectados`:state.legacy?'LEGADO · ASEDIOS DESACTIVADOS':'MUNDO CERRADO';
  const m=mapContext,size=state.size||100;m.clearRect(0,0,160,160);
  for(const c of state.communities){m.fillStyle=c.ground;m.fillRect((c.x>105?80:0),(c.y>105?80:0),state.legacy?160:80,state.legacy?160:80);const x=c.x/size*160,y=c.y/size*160;m.strokeStyle=c.color;m.beginPath();m.arc(x,y,(18+(c.vault.upgrades||0)*6)/size*160,0,Math.PI*2);m.stroke();m.fillStyle=c.vault.hp>0?c.color:'#5b514f';m.fillRect(x-3,y-3,6,6);m.font='8px Segoe UI';m.fillStyle='#e5e9df';m.fillText(c.region.slice(0,8),Math.max(2,x-18),y-8);}
  for(const p of state.players.filter(p=>p.online&&p.alive)){m.fillStyle=p.id===id?'#fff':p.communityId===state.communityId?'#9cecac':'#ee9c86';m.beginPath();m.arc(p.x/size*160,p.y/size*160,p.id===id?3:2,0,Math.PI*2);m.fill();}
  for(const mage of state.story?.mages||[]){m.fillStyle=mage.id===trackedMage?'#fff2b0':'#d2a2f4';m.fillRect(mage.x/size*160-2,mage.y/size*160-2,4,4);}
},250);

addEventListener('keydown',e=>{
  if(e.key.toLowerCase()==='u'&&!e.repeat&&state&&!$('guide').open&&!$('journal').open&&e.target.tagName!=='INPUT')act('upgrade');
  if(e.key.toLowerCase()==='t'&&!e.repeat&&state&&!$('guide').open&&!$('journal').open&&e.target.tagName!=='INPUT')act('deposit');
});
setInterval(()=>{
  if(state){const level=state.vault.upgrades||0;$('territory').textContent=`Radio ${18+level*6} · ${level<3?'U: ampliar por '+(60+level*30)+' materiales':'mejora máxima'}`;}
},500);







