shader_type spatial;
render_mode blend_mix,depth_draw_always,cull_back,diffuse_lambert,specular_disabled,vertex_lighting;

uniform vec4 snow : hint_color;
uniform vec4 mountains : hint_color;
uniform vec4 plains : hint_color;
uniform vec4 shore : hint_color;
uniform vec4 seafloor : hint_color;

uniform sampler2D texture_noise;

varying vec3 v;
varying vec3 n;
void vertex()
{
	v = VERTEX;
	n = NORMAL;
}

void fragment() {
	vec2 noise_uv = v.xz / 512.0;
	float noise = textureLod(texture_noise, noise_uv, 0.0).r * 2.0 - 1.0;
	float snowy = smoothstep(-0.15, 0.15, noise) * 32.0;
	
	float y = v.y;
	float ny = n.y;
	float fade = 6.0;
	
	vec3 color = shore.rgb;
	color = mix(color, plains.rgb, smoothstep(15.25, 16.25, y));
	color = mix(color, mountains.rgb, smoothstep(42.0, 128.00, y));
	color = mix(color, snow.rgb, smoothstep(90.0, 250.0 + fade + snowy, y));
	color = mix(seafloor.rgb, color, smoothstep(-3.0, 3.0, y));
	
	ALBEDO = color;
}
