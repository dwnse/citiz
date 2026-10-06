shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D atlas : source_color, filter_linear_mipmap;
uniform bool infected = false;
instance uniform vec4 insignia : source_color = vec4(0.38,0.47,0.32,1.0);
void fragment() {
	vec3 source = texture(atlas, UV).rgb;
	float lightness = dot(source, vec3(0.2126,0.7152,0.0722));
	vec3 muted = mix(vec3(lightness),source,0.48);
	if (infected) {
		float green = smoothstep(0.015,0.12,source.g-max(source.r,source.b));
		muted = mix(muted,vec3(0.34,0.40,0.27)*(0.65+lightness),green);
	} else {
		// The source's yellow helmet becomes weathered olive equipment.
		float yellow = smoothstep(0.06,0.2,min(source.r,source.g)-source.b);
		muted = mix(muted,vec3(0.23,0.28,0.18)*(0.7+lightness),yellow);
		float blue = smoothstep(0.02,0.15,source.b-source.r);
		muted = mix(muted,insignia.rgb*(0.55+lightness),blue);
	}
	ALBEDO=muted;
	ROUGHNESS=0.92;
}
