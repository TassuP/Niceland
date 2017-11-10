extends Node

export var enabled = true
var use_threading = false # <- doesn't work
export var plot_distance = 0.3 # percent of terrain size
var upd_distance = 100.0
var original_plot_distance
var thread
var plr
var last_gen_pos = Vector3(-99999,0,-99999)


export(NodePath) var put_under
var object_library
var objects = []

var seed_offset = 0

func _ready():
	if(enabled == false):
		set_process(false)
		return
		
	if(use_threading):
		thread = Thread.new()
	
	randomize()
	seed_offset = randi()%100
	put_under = get_node(put_under)
	plr = get_parent()
	object_library = get_children()
	
	original_plot_distance = plot_distance
	
	

func _process(delta):
	
	# Don't do anything while flying
	if(GameSettings.hold_generating):
		return
	
	var pos = plr.get_global_transform().origin
#	pos -= plr.get_global_transform().basis.z * plot_distance
	pos.y = 0.0
	
#	plot_distance = original_plot_distance * GameSettings.terrain_size / 2
#	upd_distance = plot_distance / 4
	plot_distance = original_plot_distance * GameSettings.terrain_size / 2
	plot_distance = lerp(GameSettings.terrain_size / 2.0, plot_distance, GameSettings.geometry_level)
	upd_distance = plot_distance / 4
	
	if(fast_distance(pos, last_gen_pos) > upd_distance):
		last_gen_pos = pos
		
		if(use_threading):
			if(thread.is_active()):
				thread.wait_to_finish()
			thread.start(self,"run_thread")
		else:
			run_thread(null)

func do_landing_again():
	var i = objects.size()-1
	while(i >= 0):
		if(objects[i].set_to_ground):
			objects[i].do_landing = true
			objects[i].set_process(true)
		i -= 1

func run_thread(userdata):
	var start_time = OS.get_ticks_msec()
	
	set_process(false)
	upd_objects()
	delete_far_objects(last_gen_pos, plot_distance)
	set_process(true)
	
	var end_time = OS.get_ticks_msec()
	var total_time = end_time - start_time
	
	GameSettings.object_plotting_time = total_time

func upd_objects():
	
	var pos = plr.get_global_transform().origin
	pos.y = 0.0
	
	if(enabled == false):
		return
	
	pos.x = round(pos.x)
	pos.y = 0.0
	pos.z = round(pos.z)
	
	# Plot new objects
	var i = 0
	while(i < object_library.size()):
		var obj = object_library[i]
		if(obj.enabled):
			if(obj.initialized == false):
				obj.init()
			
			var x = -plot_distance
			while(x < plot_distance):
				var z = -plot_distance
				while(z <  plot_distance):
					var p = Vector3(x, 0, z) + pos
#					process_point(p, pos)
					
					var xx = stepify(p.x, obj.spacing)
					var zz = stepify(p.z, obj.spacing)
					
					# Is terrain type suitable for object
					var t_type = Height_Main.gen(xx, zz, true, false)
					var go = false
					if(t_type == Height_Main.TerrainType.ocean && obj.ocean == true):
						go = true
					elif(t_type == Height_Main.TerrainType.lake && obj.lake == true):
						go = true
					elif(t_type == Height_Main.TerrainType.swamp && obj.swamp == true):
						go = true
					elif(t_type == Height_Main.TerrainType.plains && obj.plains == true):
						go = true
					elif(t_type == Height_Main.TerrainType.hill && obj.hill == true):
						go = true
					elif(t_type == Height_Main.TerrainType.mountain && obj.mountain == true):
						go = true
					elif(t_type == Height_Main.TerrainType.snow && obj.snow == true):
						go = true
					
					# Terrin is OK
					if(go == true):
						
#						print("Plotting ", obj.get_name())
						
						# Plot object
						seed_from_pos(xx, zz, i)
						var r = float(randi()%100)
						r *= 1.0 - Height_Main.randf_pattern(xx / obj.pattern_size, zz / obj.pattern_size)
						if(r <= obj.chance * 100.0):
							var np = Vector3(xx, p.y, zz)
							if(is_place_free(np)):
								np.y = Height_Main.gen(xx, zz, false, true)
								if(np.y >= obj.min_y && np.y <= obj.max_y):
									var inst = object_library[i].duplicate()
									inst.hide()
									inst.spawn_x = np.x
									inst.spawn_z = np.z
									put_under.add_child(inst)
									inst.set_translation(np)
									objects.append(inst)
									inst.on_plot()
									
								
					z += obj.spacing
				x += obj.spacing
		i += 1

func fast_distance(a, b):
	var c = max(abs(a.x-b.x) , abs(a.z-b.z))
	return c

func delete_far_objects(pos, dist):
	
	pos.x = round(pos.x)
	pos.y = 0.0
	pos.z = round(pos.z)
	
	# Delete far objects
	var i = objects.size()-1
	var dels = 0
	while(i >= 0):
		var obj_pos = Vector3(objects[i].spawn_x, pos.y, objects[i].spawn_z)
		if(fast_distance(obj_pos, pos) > dist):
			objects[i].queue_free()
			objects.remove(i)
			dels += 1
		i -= 1

func seed_from_pos(x, z, offset_add):
#	x = round(x/spacing)*spacing
#	z = round(z/spacing)*spacing
	var s = round((x*x)+(z*z)+seed_offset+offset_add)
	s = s*s
	seed(abs(s))

func is_place_free(pos):
	
	var obs = put_under.get_children()
	var i = 0
	while(i < obs.size()):
		
#		var p = obs[i].get_global_transform().origin
		
		if(abs(obs[i].spawn_x - pos.x) < obs[i].spacing / 2):
			if(abs(obs[i].spawn_z - pos.z) < obs[i].spacing / 2):
				return false
#		if(abs(objects[i].spawn_x - pos.x) < objects[i].spacing / 2):
#			if(abs(objects[i].spawn_z - pos.z) < objects[i].spacing / 2):
#				return false
		
		i += 1
	return true
