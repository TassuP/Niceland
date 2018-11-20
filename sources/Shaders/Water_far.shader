shader_type spatial;
render_mode blend_mix, unshaded;
uniform vec4 water_color : hint_color;
uniform vec4 horizon_color : hint_color;
uniform float fade_start = 128.0;
uniform float fade_end = 256.0;
uniform float far = 1024.0;

void fragment() {
//	ALBEDO = water_color.rgb;
	ALPHA = smoothstep(fade_start, fade_end, -VERTEX.z);
	ALBEDO = mix(water_color.rgb, horizon_color.rgb, smoothstep(fade_start, far, -VERTEX.z));
}
