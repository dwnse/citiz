shader_type spatial;
render_mode cull_disabled;
void vertex(){
 VERTEX.z+=sin(UV.x*6.0-TIME*2.4+UV.y*2.0)*UV.x*.13;
}
void fragment(){
 vec2 p=UV-vec2(.5,.5);
 float peak=step(abs(p.x),(.28-p.y)*.65)*step(-.20,p.y)*step(p.y,.28);
 float hollow=step(abs(p.x),(.09-p.y)*.75)*step(-.20,p.y)*step(p.y,.09);
 ALBEDO=mix(vec3(.015,.23,.52),vec3(.9,.95,1.0),max(0.0,peak-hollow));
 ROUGHNESS=.85;
}
