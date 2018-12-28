shader_type canvas_item;
render_mode blend_mix;

//vec3 rgb2hsv(vec3 c)
//{
//    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
//    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
//    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
//
//    float d = q.x - min(q.w, q.y);
//    float e = 1.0e-10;
//    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
//}
//vec3 hsv2rgb(vec3 c)
//{
//    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
//    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
//    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
//}

void fragment() {
	
	vec3 c = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	
	// Soft blur
	c *= 4.0;
	c += textureLod(SCREEN_TEXTURE, SCREEN_UV, 2.0).rgb;
	c += textureLod(SCREEN_TEXTURE, SCREEN_UV, 1.0).rgb;
	c /= 6.0;
	
	// Sepia hue
//	float fr = (c.r * 0.393) + (c.g * 0.769) + (c.b * 0.189);
//	float fg = (c.r * 0.349) + (c.g * 0.686) + (c.b * 0.168);
//	float fb = (c.r * 0.272) + (c.g * 0.534) + (c.b * 0.131);
//	c.rgb = mix(c.rgb, vec3(fr, fg, fb), 0.2);
	
	// Color tone
//	float tone_lum = lum;
//	float fr = (c.r * 0.393) + (c.g * 0.769) + (c.b * 0.189);
//	float fg = (c.r * 0.349) + (c.g * 0.686) + (c.b * 0.168);
//	float fb = (c.r * 0.272) + (c.g * 0.534) + (c.b * 0.131);
//	vec3 new_tone = rgb2hsv(vec3(fr,fg,fb));
//	new_tone.r = 0.67;
//	new_tone = hsv2rgb(new_tone);
//	c.rgb = mix(c.rgb, new_tone, 0.2 * (1.0 - tone_lum));
	// Vignette
//	float vignette = 1.0 - distance(SCREEN_UV * vec2(1.0, 0.8), vec2(0.5, 0.5)* vec2(1.0, 0.8)) * 2.0;
////	vignette = smoothstep(-0.75, 0.75, vignette);
//	vignette = clamp((vignette / 2.0 + 0.5) + lum, 0.0, 1.0);
//	c.rgb *= vignette;
	
	// Finalize color
	COLOR.r = clamp(c.r, 0.0, 1.0);
	COLOR.g = clamp(c.g, 0.0, 1.0);
	COLOR.b = clamp(c.b, 0.0, 1.0);
	COLOR.a = 1.0;
}



