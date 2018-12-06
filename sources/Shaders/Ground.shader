shader_type spatial;
render_mode blend_mix,depth_draw_always,cull_back,diffuse_lambert,specular_disabled,world_vertex_coords,vertex_lighting;

uniform vec4 snow : hint_color;
uniform vec4 mountains : hint_color;
uniform vec4 plains : hint_color;
uniform vec4 shore : hint_color;
uniform vec4 seafloor : hint_color;

uniform sampler2D texture_noise;

//varying float y;
//varying float y2;
//varying float ny;
//varying vec2 noise_uv;
//
varying vec3 v;
varying vec3 n;
void vertex()
{
	v = VERTEX;
	n = NORMAL;
}
//void vertex() {
//	noise_uv = VERTEX.xz / 512.0;
//	float noise = textureLod(texture_noise, noise_uv, 0.0).r * 2.0 - 1.0;
//	y = VERTEX.y + noise * 20.0;
//	y2 = VERTEX.y;
//	ny = NORMAL.y;
//}


void fragment() {
//	vec3 v = (INV_CAMERA_MATRIX * (INV_PROJECTION_MATRIX * vec4(VERTEX, 1.0))).xyz;
	vec2 noise_uv = v.xz / 512.0;
	float noise = textureLod(texture_noise, noise_uv, 0.0).r * 2.0 - 1.0;
	float snowy = smoothstep(-0.15, 0.15, noise) * 32.0;
//	snowy = smoothstep(0.0, 1.0, NORMAL.y) * 64.0;
	
	float y = v.y;// + noise * 20.0;
	float y2 = v.y;
	float ny = n.y;
	
	float fade = 6.0;
	
//	vec3 mount_or_plain = mix(mountains.rgb, plains.rgb, smoothstep(0.8, 0.81, ny));
	vec3 color = shore.rgb;
	color = mix(color, plains.rgb, smoothstep(15.25, 16.25, y));
//	color = mix(color, mount_or_plain.rgb, smoothstep(30.0, 31.0, y));
	color = mix(color, mountains.rgb, smoothstep(42.0, 128.00, y));
	color = mix(color, snow.rgb, smoothstep(250.0, 250.0 + fade, y + snowy));
	color = mix(seafloor.rgb, color, smoothstep(-3.0, 3.0, y2));
	
	ALBEDO = color;
}
