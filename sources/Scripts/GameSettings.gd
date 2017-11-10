extends Node

var invert_mouse = false
var paused = true
var dev_mode = false
var geometry_level = 0.5 # Range from 0.0 to 1.0
var effects_level = 0.3
var shadows_on = true

var time_of_day = 0.0 # 0 -> 86400
var day_phase = 0.0 # -PI -> PI
var game_timescale = 60.0

var debug_label = "/root/Main/2D/Debug label"
var player = "/root/Main/3D/Player"

var terrain_size = 0 # value updated in Terrain.gd
var terrain_generation_time = 0
var object_plotting_time = 0

var avg_fps = 0
var start_msec = 0

var plr_transform
var trail = []

var hold_generating = false

var game_seed = 0
var rand_offset_1 = 0.0
var rand_offset_2 = 0.0
var rand_offset_3 = 0.0


func reload_all():
	print("GameSettings: reload_all")
	get_tree().reload_current_scene()

func _ready():
	
	randomize()
	game_seed = randi()
	rand_offset_1 = randf() * 512
	rand_offset_2 = randf() * 512
	rand_offset_3 = randf() * 512
	
	time_of_day = randi()%86400
	
#	reload_all()
	
	
func _process(delta):
	
	upd_time_of_day(delta)
	
	if(has_node(player)):
		plr_transform = get_node(player).get_global_transform()
	
	upd_debug_label()

func teleport(to):
	
	get_node("/root/Main/3D/Terrain/Ground").cancel = true
	
	to.y = Height_Main.gen(to.x, to.y, false, true)
	print("Teleport to ", to)
	plr_transform = get_node(player).get_global_transform()
	plr_transform.origin = to
#	get_node(player).set_global_transform(plr_transform)
	reload_all()

func msec2str(t):
	var seconds = int(t / 1000) % 60 ;
	var minutes = int((t / (1000*60)) % 60);
	var msec = t - (minutes * 60 * 1000) - (seconds * 1000)
	return str(minutes,":",seconds,".",msec)

func upd_debug_label():
	
	get_node(debug_label).set_visible(dev_mode)
	
	if(Engine.get_frames_drawn() < 120):
		avg_fps = Engine.get_frames_per_second()
	else:
		avg_fps = lerp(avg_fps, Engine.get_frames_per_second(), 0.005)
	
	var s = str("Fps = ", Engine.get_frames_per_second(), " / ", avg_fps)
#	s += str("\n\n","Time of day = ", get_tod_str())
	s += str("\n","Terrain generation time = ", msec2str(terrain_generation_time))
	if(has_node(player)):
		var pos = get_node(player).get_global_transform().origin
#		s += str("\n","Location ", pos)
		var ttype = Height_Main.gen(pos.x, pos.z, true, true)
#		s += str("\n","Terrain = ", Height_Main.get_terrain_type_str(ttype))
	
	get_node(debug_label).set_text(s)

func get_tod_str():
	
	# Hours
	var h = int(time_of_day / (60 * 60)) % 24;
	var r = str(h)
	
	# Minutes
	var m = int(time_of_day / 60) % 60;
	if(m < 10):
		r += str(":0", m)
	else:
		r += str(":",m)
	
	# Seconds
	var s = int(time_of_day) % 60 ;
	if(s < 10):
		r += str(":0", s)
	else:
		r += str(":",s)
	
	return r

func upd_time_of_day(delta):
	
	if(paused == false):
		time_of_day += delta * game_timescale
	
	day_phase = time_of_day / (86400.0 / (PI * 2.0))
	
#	if(Input.is_key_pressed(KEY_X)):
#		time_of_day += delta * 60 * 60 * 2
#	if(Input.is_key_pressed(KEY_Z)):
#		time_of_day -= delta * 60 * 60 * 2
		
	if(time_of_day > 86400.0):
		time_of_day -= 86400.0
	if(time_of_day < 0.0):
		time_of_day += 86400.0
		