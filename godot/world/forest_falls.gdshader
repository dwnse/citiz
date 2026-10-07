shader_type spatial;
render_mode cull_disabled;
void fragment(){
 float stripes=sin(UV.x*47.0+sin(UV.y*8.0-TIME*2.0)*.45);
 float sparkle=pow(.5+.5*sin(UV.y*36.0-TIME*8.0+UV.x*9.0),14.0);
 ALBEDO=mix(vec3(.015,.55,.72),vec3(.53,.91,.96),smoothstep(.35,.88,stripes));
 ALBEDO+=sparkle*.18;
 EMISSION=ALBEDO*.2;
 ROUGHNESS=.42;
}
