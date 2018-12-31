extends Spatial

# Main settings
export var verbose = false
export var random_seed = 0
export var far_distance = 0.1
export var spacing = 10.0
export var area_1_treshold = 0.3
export var area_2_treshold = 0.3
export var area_2_size_multiplier = 10.0
export var slope_min = 0.0
export var slope_max = 0.2
export var altitude_min = 8.0
export var altitude_max = 1024.0

# These are calculated from ground_size
var view_distance
var upd_distance
var del_distance

var thread = Thread.new()
var view_point
var last_point
var gen_time

export(String, FILE) var obj_scene
var noise = preload("res://Scripts/HeightGenerator.gd").new()

var obj_array = []
var obj_tr_array = []

func _ready():
	
	set_process(false)
	if(is_visible_in_tree() == false):
		return
	
	noise.init()
	
	obj_scene = load(obj_scene)
	
	view_distance = float(Globals.ground_size)
	upd_distance = float(view_distance)
	view_distance *= far_distance
	upd_distance *= far_distance / 4.0
	del_distance = view_distance * 2.0
	
	random_seed = float(random_seed) * 1234.56
	
	view_point = get_vp()
	last_point = view_point
	
	call_deferred("start_generating")

func get_vp():
	var p = get_viewport().get_camera().get_global_transform().origin
#	p -= get_viewport().get_camera().get_global_transform().basis.z * view_distance * 0.8
	p.y = 0.0
	return p

func _process(delta):
	view_point = get_vp()
	if(last_point.distance_to(view_point) > upd_distance):
		start_generating()

func start_generating():
	gen_time = OS.get_ticks_msec()
	set_process(false)
	view_point = get_vp()
	view_point.x = stepify(view_point.x, spacing)
	view_point.z = stepify(view_point.z, spacing)
	
	thread.start(self, "generate", [view_point, obj_array, obj_tr_array])

func finish_generating():
	var ret = thread.wait_to_finish()
	obj_array = ret[0]
	obj_tr_array = ret[1]
	
	gen_time = OS.get_ticks_msec() - gen_time
	if(verbose or gen_time >= 2000.0):
		print(name," x ", obj_array.size()," in ", gen_time / 1000.0, " s")
	
	last_point = view_point
	
	if(Globals.generate_just_once == false):
		set_process(true)

func generate(userdata):
	
	var pos = userdata[0]
	var o_arr = userdata[1]
	var t_arr = userdata[2]
	
	pos.x = stepify(pos.x, spacing)
	pos.z = stepify(pos.z, spacing)
	
	# Delete far objects
	if(o_arr.size() > 0):
		var i = o_arr.size() - 1
		while(i >= 0):
			var p = o_arr[i].global_transform.origin
			if(view_point.distance_to(p) > del_distance):
				if(view_point.distance_to(t_arr[i]) > del_distance):
					o_arr[i].call_deferred("queue_free")
					o_arr.remove(i)
					t_arr.remove(i)
			i -= 1
	
	
	
	var w = stepify(float(view_distance), spacing)
	var x = -w
	while(x < w):
		var z = -w
		while(z < w):
			
			var xx = x + pos.x
			var zz = z + pos.z
			
			var r = noise._noise.get_noise_2d((xx+random_seed) * 123.0 / area_2_size_multiplier, zz * 123.0 / area_2_size_multiplier + random_seed)
			
			if(r >= area_2_treshold):
				var rp = Vector3(r, 0.0, 0.0)
				var a2_aff = clamp(((r - area_2_treshold) / (1.0 - area_2_treshold)) * 3.0, 0.0, 1.0)
				
				r = noise._noise.get_noise_2d(xx * 1234.0, zz * 1234.0)
				
				if(r >= area_1_treshold):
					# Randomize position
					rp.z = r
					rp *= 1000.0
					xx += sin(rp.x) * spacing
					zz += cos(rp.z) * spacing
					
					# Y-position
					var y = noise.get_h(Vector3(xx, 0.0, zz)) + 0.3
					if(y >= altitude_min && y <= altitude_max):
						
						# Slopes
						var difx = noise.get_h(Vector3(xx + 2.0, 0.0, zz))
						difx -= noise.get_h(Vector3(xx - 2.0, 0.0, zz))
						var difz = noise.get_h(Vector3(xx, 0.0, zz + 2.0))
						difz -= noise.get_h(Vector3(xx, 0.0, zz - 2.0))
						
						var dif = max(abs(difx), abs(difz)) / 5.0
						
						if(dif >= slope_min && dif <= slope_max):
							var tr_origin = Vector3(xx, y, zz)
							
							if(t_arr.has(tr_origin) == false):
								var inst = obj_scene.instance()
								inst.transform.origin = tr_origin
								o_arr.append(inst)
								t_arr.append(tr_origin)
								call_deferred("add_child", inst)
			z += spacing
		x += spacing
		
	call_deferred("finish_generating")
	return [o_arr, t_arr]

