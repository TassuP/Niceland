shader_type spatial;
render_mode blend_mix,depth_draw_never,cull_disabled,diffuse_burley,specular_disabled,unshaded;
uniform vec4 cloud_color : hint_color;
uniform vec4 lining_color : hint_color;
uniform vec4 sun_color : hint_color;
uniform vec4 sky_color : hint_color;
uniform vec4 horizon_color : hint_color;
uniform sampler2D texture_noise;
uniform sampler2D texture_stars;

uniform float cloudiness : hint_range(0.0, 1.0) = 0.5;
uniform float fluffiness : hint_range(0.0, 1.0) = 1.0;
uniform vec2 wind_uv_offset = vec2(0.0, 0.0);
uniform vec2 wind_dir = vec2(1.0, 0.0);
uniform float wind_speed = 0.01;
uniform float camera_y = 0.0;
uniform vec3 sun_dir = vec3(1.0, 0.0, 0.0);


varying float a1;
varying float a2;
varying float b1;
varying float b2;



void vertex() {
	float t = 0.1 * fluffiness;
	a1 = clamp(cloudiness - t, 0.0, 1.0 - t);
	a2 = clamp(cloudiness + t, 0.0 + t, 1.0);
	
	t = 0.1;
	b1 = clamp(cloudiness - t, 0.0, 1.0 - t);
	b2 = clamp(cloudiness + t, 0.0 + t, 1.0);
}




void fragment() {
	// Get projected UV for the clouds
	vec4 invcamx = INV_CAMERA_MATRIX[0];
	vec4 invcamy = INV_CAMERA_MATRIX[1];
	vec4 invcamz = INV_CAMERA_MATRIX[2];
	mat3 invcam = mat3(invcamx.xyz, invcamy.xyz, invcamz.xyz);
	vec3 world_pos = (VERTEX) * invcam + camera_y;
	vec3 normal = normalize(world_pos);
	vec2 uv = normal.xz / (1.5+abs(normal.y) * 10.0);
	vec2 uv_stars = normal.xz / (1.5+abs(normal.y) * 2.0);
	vec2 uv2 = uv / 2.0;
	uv += wind_uv_offset / 20.0;
	uv2 += wind_uv_offset / 150.0;
	uv_stars += vec2(-TIME, 0.0) / 180.0;
	
	vec4 stars_tex = textureLod(texture_stars, uv_stars * 2.0, 0.0);
	
	// Cloud noise
	float noise = textureLod(texture_noise, uv, 0.0).r;
	noise += textureLod(texture_noise, uv2, 0.0).r;
	noise /= 2.0;
	float noise2 = textureLod(texture_noise, uv * 1.5, 0.0).r;
	
	// Cloudiness
	float a = 1.0 - smoothstep(a1, a2, noise);
	float b = 1.0 - smoothstep(b1, b2, noise);
	
	// Final mix
//	vec3 bg = textureLod( SCREEN_TEXTURE, SCREEN_UV, smoothstep(128.0, 512.0, -world_pos.z) * 2.0).rgb;
	
	vec3 near_sun = mix(cloud_color.rgb, sun_color.rgb, 1.0 - b * noise2);
	vec3 opposite_sun = mix(cloud_color.rgb, lining_color.rgb, b * noise2);
	float sun_dot = dot(normal, sun_dir);
	ALBEDO = mix(opposite_sun, near_sun, smoothstep(0.5, 1.0, sun_dot));
	ALBEDO = mix(horizon_color.rgb, ALBEDO, smoothstep(0.0, 0.2, abs(normal.y)));
//	ALPHA = a;
	
	
	// Starsky
	float star = smoothstep(0.8, 1.0, stars_tex.r);
	star *= 1.0 - smoothstep(-0.3, 0.3, sun_dir.y);
	ALBEDO += vec3(star / 2.0) * (1.0 - a);
	float alpha = max(a, star);

	
	// Mix clouds and stars with bg sky
	alpha = clamp(alpha, 0.0, 1.0);
	float ny = 1.0 - abs(normal.y);
	ny = ny * ny * ny * ny;
	ny = clamp(ny, 0.0, 1.0);
	vec3 sky = mix(sky_color.rgb, horizon_color.rgb, ny);
	
	// Sun halo
	sky = mix(sky, sun_color.rgb, smoothstep(0.0, 1.0, sun_dot * pow(sun_dot, 2.0)) * ny);
	// Sun
	sky = mix(sky, sun_color.rgb * 2.0, smoothstep(0.99, 1.0, sun_dot * abs(sun_dot)));
	
	ALBEDO = mix(ALBEDO, sky, 1.0 - alpha);
//	ALPHA = 1.0; // alpha;

	ALBEDO.r = clamp(ALBEDO.r, 0.0, 1.0);
	ALBEDO.g = clamp(ALBEDO.g, 0.0, 1.0);
	ALBEDO.b = clamp(ALBEDO.b, 0.0, 1.0);
}
