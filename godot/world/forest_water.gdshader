shader_type spatial;
render_mode cull_disabled;
uniform sampler2D river_mask : filter_nearest, repeat_disable;
uniform vec2 map_offset=vec2(0.0);
varying vec2 map_uv;
varying vec2 point;
void vertex(){
 vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 point=world.xz;
 map_uv=(world.xz-map_offset)/100.0;
}
void fragment(){
 if(texture(river_mask,map_uv).r<0.5)discard;
 float depth=0.0;
 for(int i=0;i<8;i++){
  float a=float(i)*0.785398;
  depth+=texture(river_mask,map_uv+vec2(cos(a),sin(a))*0.012).r;
 }
 vec2 moving=point+vec2(sin(point.y*.46)*.40,TIME*.35);
 vec2 cell=floor(moving/vec2(2.8,1.5));
 vec2 local=fract(moving/vec2(2.8,1.5));
 float seed=fract(sin(dot(cell,vec2(12.9898,78.233)))*437.585);
 float line=abs(local.y-(.40+sin(local.x*3.14159)*.13));
 float wave=(1.0-smoothstep(.018,.06,line))*smoothstep(.15,.30,local.x)*(1.0-smoothstep(.65,.85,local.x))*step(.44,seed);
 float curls=pow(.5+.5*sin(point.y*2.4+sin(point.x*.65)-TIME*.9),24.0)*.20;
 vec3 water=mix(vec3(0.01,0.38,0.58),vec3(0.018,0.69,0.82),1.0-depth/8.0);
 ALBEDO=water+wave*0.23+curls*0.09;
 float foam=(1.0-smoothstep(4.0,7.5,depth))*(0.45+wave*0.4);
 ALBEDO=mix(ALBEDO,vec3(0.64,0.96,1.0),foam);
 EMISSION=ALBEDO*0.23;
 ROUGHNESS=0.25;
 SPECULAR=0.5;
}
