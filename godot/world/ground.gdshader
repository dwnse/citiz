shader_type spatial;
render_mode diffuse_burley;
varying vec3 world_pos;
uniform sampler2D forest_water_mask : filter_nearest, repeat_disable;
uniform sampler2D mountain_water_mask : filter_nearest, repeat_disable;
float hash(vec2 p) { vec3 q=fract(vec3(p.xyx)*0.1031); q+=dot(q,q.yzx+33.33); return fract((q.x+q.y)*q.z); }
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
 vec3 asphalt=mix(vec3(0.19,0.22,0.22),vec3(0.30,0.31,0.28),n);
 float cracks=1.0-smoothstep(0.01,0.05,abs(noise(p*1.7)-0.48));
 asphalt*=1.0-cracks*0.25;
 vec3 terrain=mix(grass,dirt,smoothstep(0.60,0.80,n)*0.65);
 ALBEDO=mix(terrain,asphalt,trail);
 // Forest palette fades at its existing regional boundary; all other biomes keep their art.
 float forest=(1.0-smoothstep(98.0,105.0,p.x))*(1.0-smoothstep(98.0,105.0,p.y));
 if(forest>0.5 && texture(forest_water_mask,p/100.0).r>0.5)discard;
 vec3 cartoon_grass=mix(vec3(0.10,0.25,0.027),vec3(0.25,0.40,0.065),noise(p*0.20));
 cartoon_grass*=0.96+noise(p*4.1)*0.08;
 vec3 sand=mix(vec3(0.46,0.33,0.14),vec3(0.53,0.39,0.18),noise(p*2.3));
 float clearing=1.0-smoothstep(0.0,1.0,length(max(abs(p-vec2(50.0))-vec2(6.0,6.0),vec2(0.0)))+(noise(p*1.5)-.5)*.7);
 float yards=min(length(p-vec2(40.0,44.0))-3.8,length(p-vec2(59.0,56.0))-3.8);
 yards=min(yards,length(p-vec2(61.0,40.0))-1.9);
 yards=min(yards,length(p-vec2(71.0,53.0))-3.6);
 clearing=max(clearing,1.0-smoothstep(0.0,1.0,yards));
 float path_distance=min(abs(p.x-(50.0+sin(p.y*0.12)*1.7)),abs(p.y-(50.0+sin(p.x*0.11)*1.8)));
 float paths=1.0-smoothstep(2.0,2.6,path_distance+(noise(p*1.25)-0.5)*.7);
 vec3 woodland=mix(cartoon_grass,sand,max(clearing,paths));
 float shore=0.0;
 for(int i=0;i<8;i++){
  float a=float(i)*0.785398;
  shore+=texture(forest_water_mask,p/100.0+vec2(cos(a),sin(a))*0.015).r;
 }
 woodland=mix(woodland,sand,shore*0.09);
 woodland*=0.98+noise(p*12.0)*0.04;
 ALBEDO=mix(ALBEDO,woodland,forest);
 float mountain=(1.0-smoothstep(99.0,105.0,p.x))*smoothstep(105.0,112.0,p.y);
 if(mountain>.5 && texture(mountain_water_mask,(p-vec2(0.0,110.0))/100.0).r>.5)discard;
 vec3 snow=mix(vec3(.65,.78,.91),vec3(.90,.96,1.0),noise(p*.42));
 float thaw=smoothstep(.48,.66,noise(p*.105))*.45+smoothstep(175.0,207.0,p.y)*.85;
 vec3 alpine=mix(snow,vec3(.16,.32,.065),clamp(thaw,0.0,.98));
 float plaza=1.0-smoothstep(0.0,1.0,length(max(abs(p-vec2(50.0,160.0))-vec2(10.0,10.0),vec2(0.0))));
 float mountain_paths=min(abs(p.x-(50.0+sin(p.y*.08)*1.6)),abs(p.y-(160.0+sin(p.x*.11)*1.8)));
 mountain_paths=min(mountain_paths,abs(p.y-188.0));
 float alpine_trail=1.0-smoothstep(2.0,2.65,mountain_paths+(noise(p*1.25)-.5)*.7);
 alpine=mix(alpine,sand,max(plaza,alpine_trail));
 ALBEDO=mix(ALBEDO,alpine,mountain);
 ROUGHNESS=0.95;
}
