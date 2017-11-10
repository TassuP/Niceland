extends Node

export(NodePath) var plr
export(NodePath) var plr_ctrl
export(NodePath) var env
export(NodePath) var cam
export(NodePath) var terrain
export(NodePath) var sun

var sky

export var day_color_sky = Color(0, 0.2, 1)
export var day_color_horizon = Color(0.7, 0.9, 1)
export var day_color_ground = Color(0.1, 0.4, 0.2)

export var sunset_color_sky = Color(0.2, 0, 0.5)
export var sunset_color_horizon = Color(1.0, 0.3, 0)
export var sunset_color_ground = Color(1.0, 0, 0)

export var night_color_sky = Color(0, 0, 0)
export var night_color_horizon = Color(0.1, 0, 0.2)
export var night_color_ground = Color(0.1, 0, 0.2)

export var dawn_color_sky = Color(0.2, 0, 0.7)
export var dawn_color_horizon = Color(1.0, 0.5, 0)
export var dawn_color_ground = Color(1.0, 0.5, 0.5)

var sky_c = day_color_sky
var hor_c = day_color_horizon
var gnd_c = day_color_ground
var fog_c = hor_c


var fov = 65
var near = 0.1
var far = 4096

var wait_release = false

var last_sky_upd = -99999
var sky_upd_interval = 60 # seconds

func _ready():
	plr = get_node(plr)
	plr_ctrl = get_node(plr_ctrl)
	env = get_node(env).get_environment()
	cam = get_node(cam)
	terrain = get_node(terrain)
	sun = get_node(sun)
	sky = env.get_sky()
	
	# Set camera view distance
	fov = cam.get_fov()
	near = cam.get_znear()
	var far_min = terrain.patch_size_min
	var far_max = terrain.patch_size_max
	far = lerp(far_min, far_max, GameSettings.geometry_level)
	cam.set_perspective(fov, near, far)
	
	# Setup post processing effect quality
	setup_post_processing_effects()
	
	upd_fog()
	
func _process(delta):
	upd_fog()
	upd_sun()
	
func calc_effect_quality(from, to):
	var v = (GameSettings.effects_level - from) / (to - from)
	v = round(clamp(v*2, 0.0, 2.0))
	return int(v)
	
func setup_post_processing_effects():
	var q = 0
	sun.set_shadow(GameSettings.shadows_on)
	
	# Environment settings based on view distance
	env.set_dof_blur_far_distance(32) # far / 4.0)
	env.set_dof_blur_far_transition(far - 32)
	
	# First disable all effects
	env.set_fog_enabled(false)
	env.set_fog_depth_enabled(false)
	env.set_fog_height_enabled(false)
	env.set_ssr_enabled(false)
	env.set_dof_blur_near_enabled(false)
	env.set_dof_blur_far_enabled(false)
	env.set_glow_enabled(false)
	env.set_ssao_enabled(false)
	env.set_tonemap_auto_exposure(false)
	
	# Enable effects one by one based on settings
	if(GameSettings.effects_level <= 0.0):
		print("All effects OFF")
		return
	
	# Auto exposure
	env.set_tonemap_auto_exposure(true)
	if(GameSettings.effects_level <= 0.1):
		return
	
	# Fog
	env.set_fog_enabled(true)
	env.set_fog_depth_enabled(true)
	env.set_fog_height_enabled(true)
	if(GameSettings.effects_level <= 0.2):
		return
	
	# Glow
	env.set_glow_enabled(true)
	env.set_glow_bicubic_upscale(false)
	if(GameSettings.effects_level <= 0.2):
		return
	
	# Depth of field far blur
	env.set_dof_blur_far_enabled(true)
	q = calc_effect_quality(0.3, 1.0)
	env.set_dof_blur_far_quality(q)
	env.set_dof_blur_far_amount(0.15)
	if(GameSettings.effects_level <= 0.3):
		return
	
	# Depth of field near blur
	env.set_dof_blur_near_enabled(true)
	q = calc_effect_quality(0.4, 1.0)
	env.set_dof_blur_near_distance(4.0)
	env.set_dof_blur_near_quality(q)
	env.set_dof_blur_near_amount(0.2)
	if(GameSettings.effects_level <= 0.4):
		return
	
	# Screen-space reflections
	env.set_ssr_enabled(true)
	q = (GameSettings.effects_level - 0.5) * 2.0
	q = int(lerp(32, 256, clamp(q, 0.0, 1.0)))
	env.set_ssr_max_steps(q)
	if(GameSettings.effects_level <= 0.5):
		return
	
	# Screen-space ambient occlusion
	env.set_ssao_enabled(true)
	if(GameSettings.effects_level <= 0.6):
		return
		
	# Bicubic upscale for glow
	env.set_glow_bicubic_upscale(true)
	
	if(GameSettings.effects_level < 1.0):
		print("All post processing ON")
	else:
		print("All post processing ON and at maximum quality")
	
func setup_cam_post_processing_effects():
	env.set_dof_blur_near_enabled(true)
	env.set_dof_blur_far_enabled(true)
	env.set_tonemap_auto_exposure(true)
	env.set_dof_blur_near_enabled(true)
	
	var q = calc_effect_quality(0.15, 0.4)
	env.set_dof_blur_far_quality(q)
	
	q = calc_effect_quality(0.2, 0.4)
	env.set_dof_blur_near_quality(q)

func upd_sun():
	
	# Directional Light angle
	var sun = get_tree().get_nodes_in_group("Sun")[0]
	var pos = sun.get_global_transform().origin
	var a = GameSettings.day_phase + PI/3.0
	var celesial_pole = Vector3(0, 1, -1).normalized()
	var dir = Vector3(1, 0, 0)
	dir = dir.rotated(celesial_pole, -a)
	sun.look_at(pos + dir, Vector3(0,1,0))
	
	# Directional Light color
	var sin_a = -sin(a)
	var p = clamp(sin_a, 0.0, 1.0)
#	var c = sunset_color.linear_interpolate(daylight_color, p)
	var energy = clamp(sin_a * 1.5, 0.0, 1.0)
	if(energy > 0.0):
		sun.set_visible(true)
		sun.set_param(Light.PARAM_ENERGY, energy)
		sun.set_color(hor_c)
	else:
		sun.set_visible(false)
		
	
	
	if(abs(last_sky_upd - GameSettings.time_of_day) < sky_upd_interval):
		return
	
#	print("Update sky")
	last_sky_upd = GameSettings.time_of_day
	
	# Sun angle
	var longitude = a * 360 / (PI * 2.0) - 90.0
	var latitude = sin_a * 45.0
	sky.set_sun_longitude(longitude)
	sky.set_sun_latitude(latitude)
	
	# Sky colors
	var p_day = clamp(-sin(a), 0.0, 1.0)
	var p_night = clamp(sin(a), 0.0, 1.0)
	var p_twilight = 1.0 - (p_day + p_night)
#	p_twilight *= p_twilight
	
	sky_c = night_color_sky.linear_interpolate(day_color_sky, p_day)
	hor_c = night_color_horizon.linear_interpolate(day_color_horizon, p_day)
	gnd_c = night_color_ground.linear_interpolate(day_color_ground, p_day)
	
	if(GameSettings.time_of_day > 10500 && GameSettings.time_of_day < 54000):
		# Am
		sky_c = sky_c.linear_interpolate(dawn_color_sky, p_twilight)
		hor_c = hor_c.linear_interpolate(dawn_color_horizon, p_twilight)
		gnd_c = gnd_c.linear_interpolate(dawn_color_ground, p_twilight)
	else:
		# Pm
		sky_c = sky_c.linear_interpolate(sunset_color_sky, p_twilight)
		hor_c = hor_c.linear_interpolate(sunset_color_horizon, p_twilight)
		gnd_c = gnd_c.linear_interpolate(sunset_color_ground, p_twilight)
	
	sky.set_sky_top_color(sky_c)
	sky.set_sky_horizon_color(hor_c)
	sky.set_ground_horizon_color(hor_c)
	sky.set_ground_bottom_color(gnd_c)
	sky.set_sun_color(hor_c)

func upd_fog():
	var plr_pos = plr.get_translation()
	
	if(plr_pos.y >= Height_Main.water_level):
		# Above water
		var f = lerp(far / 2.0, 0.0, GameSettings.geometry_level)
		env.set_fog_depth_begin(f)
		env.set_fog_depth_curve(0.8)
		fog_c = sky_c.linear_interpolate(hor_c, 0.8)
	else:
		# Under water
		env.set_fog_depth_begin(0)
		env.set_fog_depth_curve(0.1)
		fog_c = sky_c / 2.0
	
	var hfog_max = plr_pos.y - 30.0
	var hfog_min = min(hfog_max - 400.0, Height_Main.water_level)
	env.set_fog_height_min(hfog_min)
	env.set_fog_height_max(hfog_max)
	
	env.set_fog_color(fog_c)
	env.set_fog_sun_color(hor_c)

