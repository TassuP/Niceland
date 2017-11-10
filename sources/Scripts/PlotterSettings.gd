extends Node

export var enabled = true
export var chance = 0.5
export var spacing = 50.0
export var min_y = 0.0
export var max_y = 1000.0
export var pattern_size = 1.0

var spawn_x = 0
var spawn_z = 0

var initialized = false
var plotted = false

# Variations
export var r_xz_offset = 1.0
export var r_hw_ratio = 0.1
export var r_scale = 0.7
export var r_rotate_y = true

# TODO: Learn how to use bitflags
#export(int, FLAGS, "Ocean", "Lake", "Swamp", "Plains", "Hill", "Mountain", "Snow") var terrain_type_flags = 0
#export(int, "Warrior", "Magician", "Thief") var character_class
export var ocean = true
export var lake = true
export var swamp = true
export var plains = true
export var hill = true
export var mountain = true
export var snow = true

export var set_to_ground = true
var do_landing = false
var t = 0.0

func init():
#	spacing = lerp(spacing_min, spacing_max, GameSettings.detail_level)
#	distance = lerp(distance_min, distance_max, GameSettings.detail_level)
	min_y += Height_Main.water_level
	max_y += Height_Main.water_level
	
#	print(terrain_type_flags)
#	get_parent().get_node("Variations").apply()
	initialized = true
	
	set_process(false)

func on_plot():
	plotted = true
	set_process(false)
	
	seed_from_pos(spawn_x, spawn_z)
	
	# scale
	var scale = get_scale()
	
	if(r_hw_ratio != 0):
		var rat = (randf()-randf())*r_hw_ratio
		scale.x *= 1.0 - rat
		scale.y *= 1.0 + rat
		scale.z *= 1.0 - rat
	
	if(r_scale > 0):
		scale *= 1.0 + (randf()-randf())*r_scale
		
	set_scale(scale)
	
	# rotation
	if(r_rotate_y):
		rotate_y(spawn_x * spawn_z * 6.28)
		
	# Position
	var tr = get_global_transform()
	if(r_xz_offset > 0):
		tr.origin.x += (randf()-randf()) * r_xz_offset
		tr.origin.z += (randf()-randf()) * r_xz_offset
		
	# Grounding
	if(set_to_ground):
		if(has_node("RayCast")):
			do_landing = true
			set_process(true)
		else:
			show()
	else:
		show()
	
	set_global_transform(tr)
	
	
func seed_from_pos(x, z):
	var s = round((x*x)+(z*z))
	s = s*s
	seed(abs(s))

func _process(delta):
	if(plotted == false):
		set_process(false)
		return
	
	
	if(do_landing):
		do_landing = false
		
		var tr = get_global_transform()
		var gen_h = false
		
		if(has_node("RayCast")):
			
			var ray = get_node("RayCast")
#			ray.force_raycast_update()
			
			if(ray.is_colliding()):
				tr.origin.y =  ray.get_collision_point().y
				ray.set_enabled(false)
				set_process(false)
				show()
		else:
			print("Missing RayCast from ", get_name())
			
		set_global_transform(tr)