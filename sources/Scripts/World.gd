extends WorldEnvironment

# Debug label
export (NodePath) var dlabel

# Random generation settings
#export var game_seed = 13
#export var ground_size = 1024.0 * 3.0
#export var ground_lod_step = 4.0
#export var ground_xz_scale = 1.5

# Wind settings
var use_wind = true
var wind_nodes
var wind_dir = Vector2(1.0, 0.0)
var wind_speed = 0.05
var wind_uv_offset = Vector2(0.0, 0.0)
export (Texture) var wind_tex

# Atmosphere, weather and time of day
export (NodePath) var sun
export (NodePath) var clouds
export (NodePath) var water
var env

var time_of_day = 48000.0 # 0 -> 86400
var day_phase = 0.0 # -PI -> PI
var game_timescale = 60.0 # 1.0 = realtime

# Sky and light colors
export var day_color_sun = Color(1,1,1,1)
export var day_color_sky = Color(0.388235,0.490196,0.890196,1)
export var day_color_horizon = Color(0.817383,0.883606,0.96875,1)
export var sunset_color_sun = Color(1,0.376471,0,1)
export var sunset_color_sky = Color(0,0.007843,0.215686,1)
export var sunset_color_horizon = Color(0.545098,0.167647,0.105882,1)
export var night_color_sun = Color(0.117647,0.12549,0.219608,1)
export var night_color_sky = Color(0.023529,0.023529,0.031373,1)
export var night_color_horizon = Color(0.047059,0.054902,0.164706,1)
export var dawn_color_sun = Color(1,0.678431,0,1)
export var dawn_color_sky = Color(0,0.082353,0.215686,1)
export var dawn_color_horizon = Color(0.545098,0.188235,0.105882,1)
var sun_c = day_color_sun
var sky_c = day_color_sky
var hor_c = day_color_horizon
var fog_c = hor_c

func _ready():
	dlabel = get_node(dlabel)
	
	sun = get_node(sun)
	clouds = get_node(clouds)
	water = get_node(water)
	env = get_environment()
	
#	print("\nexport var day_color_sun = Color(",day_color_sun,")")
#	print("export var day_color_sky = Color(",day_color_sky,")")
#	print("export var day_color_horizon = Color(",day_color_horizon,")")
#	print("export var sunset_color_sun = Color(",sunset_color_sun,")")
#	print("export var sunset_color_sky = Color(",sunset_color_sky,")")
#	print("export var sunset_color_horizon = Color(",sunset_color_horizon,")")
#	print("export var night_color_sun = Color(",night_color_sun,")")
#	print("export var night_color_sky = Color(",night_color_sky,")")
#	print("export var night_color_horizon = Color(",night_color_horizon,")")
#	print("export var dawn_color_sun = Color(",dawn_color_sun,")")
#	print("export var dawn_color_sky = Color(",dawn_color_sky,")")
#	print("export var dawn_color_horizon = Color(",dawn_color_horizon,")\n")
	
	
	# Setup wind nodes
	wind_nodes = get_tree().get_nodes_in_group("Wind")
	print(wind_nodes.size(), " nodes in Wind group")
	for n in wind_nodes:
		n.use_only_lod = !use_wind
		n.material_override.set_shader_param("texture_wind", wind_tex)
	
	randomize()
	environment.set_dof_blur_far_distance(64.0)
	environment.set_dof_blur_far_transition(Globals.ground_size * 0.5)
	
	

func _process(delta):
	var s = str("Fps: ", Performance.get_monitor(Performance.TIME_FPS), "\n")
	s = str(s, "pos: ", get_viewport().get_camera().global_transform.origin, "\n")
	dlabel.set_text(s)
	
#	if(Input.is_action_just_pressed("shoot")):
#		print_stray_nodes()
	
	if(Input.is_key_pressed(KEY_SHIFT)):
		wind_speed = lerp(wind_speed, 0.2, delta)
	else:
		wind_speed = lerp(wind_speed, 0.3, delta)
	
	
	
	upd_time_of_day(delta)
	upd_wind(delta)
	upd_sun()
	upd_fog()
	
	var a = float(OS.get_ticks_msec()) / 4000.0
	a = (sin(a+day_phase) + (cos(a / 3.0))) / 2.0
	a *= abs(a)
	a /= 7.0
	clouds.set_cloudiness(clamp(a + 0.5, 0.0, 1.0))


func upd_time_of_day(delta):
	
#	if(paused == false):
	time_of_day += delta * game_timescale
	
	day_phase = time_of_day / (86400.0 / (PI * 2.0))
	
	if(Input.is_key_pressed(KEY_X)):
		time_of_day += delta * 60 * 60 * 2
#		print(time_of_day)
	if(Input.is_key_pressed(KEY_Z)):
		time_of_day -= delta * 60 * 60 * 2
#		print(time_of_day)
		
	if(time_of_day > 86400.0):
		time_of_day -= 86400.0
	if(time_of_day < 0.0):
		time_of_day += 86400.0

func upd_wind(delta):
	if(use_wind == false):
		return
	
	wind_dir.x = sin(0.00001 * OS.get_ticks_msec())
	wind_dir.y = cos(0.00001 * OS.get_ticks_msec())
	
	# Upd wind
	wind_dir = wind_dir.normalized()
	wind_uv_offset += wind_dir * wind_speed * delta
	
	# Update nodes
	for n in wind_nodes:
		n.material_override.set_shader_param("wind_uv_offset", wind_uv_offset)
		n.material_override.set_shader_param("wind_dir", wind_dir)
		n.material_override.set_shader_param("wind_speed", wind_speed)
	
func upd_sun():
	
	# Directional Light angle
	var pos = sun.get_global_transform().origin
	var a = day_phase + PI/3.0
	var celesial_pole = Vector3(0, 1, -1).normalized()
	var dir = Vector3(1, 0, 0)
	dir = dir.rotated(celesial_pole, -a)
	sun.look_at(pos + dir, Vector3(0,1,0))
	

	
	# Sun angle
#	var longitude = a * 360 / (PI * 2.0) - 90.0
#	var latitude = sin_a * 45.0
#	sky.set_sun_longitude(longitude)
#	sky.set_sun_latitude(latitude)
	
	# Sky colors
	var p_day = clamp(-sin(a), 0.0, 1.0)
	var p_night = clamp(sin(a), 0.0, 1.0)
	var p_twilight = pow(1.0 - (p_day + p_night), 2.5)
	
	sun_c = night_color_sun.linear_interpolate(day_color_sun, p_day)
	sky_c = night_color_sky.linear_interpolate(day_color_sky, p_day)
	hor_c = night_color_horizon.linear_interpolate(day_color_horizon, p_day)
	
	if(time_of_day > 10500 && time_of_day < 54000):
		# Am
		sun_c = sun_c.linear_interpolate(dawn_color_sun, p_twilight)
		sky_c = sky_c.linear_interpolate(dawn_color_sky, p_twilight)
		hor_c = hor_c.linear_interpolate(dawn_color_horizon, p_twilight)
	else:
		# Pm
		sun_c = sun_c.linear_interpolate(sunset_color_sun, p_twilight)
		sky_c = sky_c.linear_interpolate(sunset_color_sky, p_twilight)
		hor_c = hor_c.linear_interpolate(sunset_color_horizon, p_twilight)
	
	var amb = (sky_c + hor_c) / 4.0
	amb = amb.linear_interpolate(Color(0.1, 0.1, 0.1), 0.2)
	environment.ambient_light_color = amb
	
	# Directional Light color
	var sin_a = -sin(a)
#	var p = clamp(sin_a, 0.0, 1.0)
	var energy = clamp(sin_a * 1.5, 0.0, 1.0)
	if(energy > 0.0):
		sun.set_visible(true)
		sun.set_param(Light.PARAM_ENERGY, energy * 0.1)
		sun.set_color(hor_c)
	else:
		sun.set_visible(false)
#	sun.set_visible(false)
	
	clouds.material_override.set_shader_param("sun_color", sun_c)
	clouds.material_override.set_shader_param("sky_color", sky_c)
	clouds.material_override.set_shader_param("horizon_color", hor_c)
	clouds.set_cloud_colors(sky_c.linear_interpolate(Color.black, 0.1), hor_c.linear_interpolate(Color.white, 0.1), hor_c)
	water.set_water_colors(sky_c, (sky_c + hor_c) / 2.0, hor_c)


func upd_fog():
	fog_c = sky_c.linear_interpolate(hor_c, 0.8)
	env.set_fog_color(fog_c)
	env.set_fog_sun_color(hor_c)
