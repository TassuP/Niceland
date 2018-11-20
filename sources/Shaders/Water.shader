shader_type spatial;
render_mode blend_mix,world_vertex_coords,unshaded;
uniform vec4 water_color : hint_color;
uniform vec4 foam_color : hint_color;

uniform sampler2D texture_waves;
uniform vec2 wind_uv_offset = vec2(0.0, 0.0);
uniform vec2 wind_dir = vec2(1.0, 0.0);
uniform float wind_speed = 0.1;
varying float wave;



void vertex() {
//	vec2 wind_uv_offset = wind_dir * TIME * wind_strength;
	
	vec2 wind_uv1 = (VERTEX.xz / 32.0) + wind_uv_offset / 2.0;
	vec2 wind_uv2 = (VERTEX.xz / -64.0) + wind_uv_offset / 4.0;
	vec2 wind_uv3 = (VERTEX.xz / 1024.0) + wind_uv_offset / 9.0;
	
	wave = texture(texture_waves, wind_uv1).r;
	VERTEX.y += (wave - 0.5) - (texture(texture_waves, wind_uv3).r - 0.5) * wind_speed * 30.0;
	wave += texture(texture_waves, wind_uv2).r;
	
	wave /= 2.0;
	

//	vec4 v = (INV_CAMERA_MATRIX * vec4(VERTEX, 1.0));
//	v /= v.w;
//	VERTEX.y -= smoothstep(-0.5, 0.0, v.z) * 100.0;
}




void fragment() {
	// Shoreline
	float depth = textureLod(DEPTH_TEXTURE,SCREEN_UV, 0.0).r;
	depth = depth * 2.0 - 1.0;
	depth = PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]);
	depth = depth + VERTEX.z;
//	ALPHA = clamp(depth * 2.0, 0.0, 1.0);
	depth = exp(-depth * 1.0);
	
	// Fake refraction
	vec2 ref = vec2(0.0, wave / 10.0);
	
	// Mix albedo with refracted background
	vec3 c1 = (water_color.rgb + textureLod(SCREEN_TEXTURE,SCREEN_UV + ref, -VERTEX.z / 16.0).rgb) / 2.0;
	
	// White foam top
	vec3 c2 = foam_color.rgb;
	
	// Mix 
	ALBEDO = mix(c1, c2, clamp(smoothstep(0.1, 0.2, depth) + smoothstep(0.6, 0.62, wave), 0.0, 1.0));
	
}
