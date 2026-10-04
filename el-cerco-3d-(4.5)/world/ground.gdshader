shader_type spatial;
render_mode diffuse_burley;
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=world_pos.xz;
 float n=noise(p*0.45)*0.65+noise(p*2.3)*0.25+noise(p*11.0)*0.1;
 float road=min(abs(p.x-50.0),abs(p.x-160.0));
 road=min(road,abs(p.y-105.0));
 float trail=1.0-smoothstep(2.3,4.7,road+(n-0.5)*3.0);
 vec3 grass=mix(vec3(0.19,0.26,0.075),vec3(0.40,0.45,0.15),smoothstep(0.25,0.75,n));
 vec3 dirt=mix(vec3(0.35,0.24,0.13),vec3(0.60,0.45,0.26),n);
 if(p.x>105.0){ grass=mix(grass,vec3(0.29,0.29,0.24),0.7); }
 if(p.y>105.0){ grass=mix(grass,vec3(0.24,0.28,0.25),0.6); }
 ALBEDO=mix(grass,dirt,max(trail,smoothstep(0.60,0.80,n)*0.65));
 ROUGHNESS=0.95;
}
