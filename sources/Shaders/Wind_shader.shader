shader_type spatial;
render_mode blend_mix,depth_draw_always,cull_disabled,diffuse_burley,specular_disabled,vertex_lighting;

uniform sampler2D texture_wind;
uniform vec2 wind_uv_offset = vec2(0.0, 0.0);
uniform vec2 wind_dir = vec2(0.0, 0.0);
uniform float wind_speed = 0.1;
uniform float wind_bend = 2.0;
uniform float wind_scale = 0.02;

uniform vec4 albedo : hint_color;

void vertex() {
	// Wind texture
	vec4 wpos = WORLD_MATRIX * vec4(VERTEX, 1.0);
	vec2 wind_uv = (wpos.xz * wind_scale) + wind_uv_offset;
	float wind = texture(texture_wind, wind_uv).r - 0.4;
	
	// Apply wind
	vec3 wind_offset = (inverse(WORLD_MATRIX) * vec4(wind_dir.x, 0.0, wind_dir.y, 0.0)).xyz;
	VERTEX -= wind_offset * wind * (VERTEX.y*VERTEX.y) * wind_bend * wind_speed;
}

void fragment() {
	ALBEDO = albedo.rgb;
}
