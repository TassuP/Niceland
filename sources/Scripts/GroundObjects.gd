extends MultiMeshInstance

# World node is optional
export (NodePath) var world

# Main settings
export var verbose = false
export var far_distance = 0.1
export var far_fade = false
export var spacing = 3.0
export var treshold = 0.6
export var area_treshold = 0.7
export var area_size = 1.0
export var slope_min = 0.0
export var slope_max = 0.2
export var align_with_ground = true
export var altitude_min = 8.0
export var altitude_max = 1024.0
export var base_scale = 1.0
export var random_scale = 0.3
export var index = 0
var pool_size = 0

# If the world node is found, then the following variables
# will be copied from there.
var ground_size = 1024 * 2
var ground_lod_step = 4.0

# These are calculated from ground_size
var view_distance
var upd_distance

var thread = Thread.new()
var view_point
var last_point
var gen_time

var lod_multimesh
var lod_dist = 16.0
var has_lod = false
var use_only_lod = false

var has_collider = false
var col_shape
export (Mesh) var collision_mesh

var hidden_transform
var noise = preload("res://Scripts/HeightGenerator.gd").new()

func _ready():
	
	set_process(false)
	if(is_visible_in_tree() == false):
		return
	
	if(world != null):
		if(verbose):
			print("Copying ground object settings from World")
		world = get_node(world)
		ground_size = world.ground_size
		ground_lod_step = world.ground_lod_step
	else:
		if(verbose):
			print("Using default settings for ground objects")
	
	noise.init(world)
	
#	view_distance = float(ground_size) / 64.0
#	upd_distance = float(view_distance) / 8.0
	view_distance = float(ground_size)
	upd_distance = float(view_distance)
	view_distance *= far_distance
	upd_distance *= far_distance / 4.0
	
	lod_dist = view_distance * 0.5
	if(use_only_lod):
		lod_dist = -1
	
	var fade_end = view_distance
	var fade_start = fade_end - 24.0
	
	multimesh.set_instance_count(pool_size)
	
	if(has_node("Lod")):
		lod_multimesh = get_node("Lod")
		lod_multimesh.multimesh.set_instance_count(pool_size)
		has_lod = true
		
		if(far_fade):
			$Lod.material_override.set_shader_param("fade_start", fade_start);
			$Lod.material_override.set_shader_param("fade_end", fade_end);
	
	if(collision_mesh != null):
		has_collider = true
		col_shape = collision_mesh.create_convex_shape()
		var st = StaticBody.new()
		st.name = "Collider"
		add_child(st)
	
	
	
	index = float(index) * 123.456
	
	view_point = get_vp()
	last_point = view_point
	
	hidden_transform = Transform.IDENTITY.scaled(Vector3(1,1,1))
	hidden_transform.origin = Vector3(0.0, -9999.9, 0.0)
	
	call_deferred("start_generating")

func get_vp():
	var p = get_viewport().get_camera().get_global_transform().origin
	p -= get_viewport().get_camera().get_global_transform().basis.z * view_distance * 0.8
	p.y = 0.0
	return p

func _process(delta):
	view_point = get_vp()
	if(last_point.distance_to(view_point) > upd_distance):
		start_generating()
	
	

func start_generating():
#	print("Start generating ground objects, seed = ", game_seed)
	gen_time = OS.get_ticks_msec()
	set_process(false)
	view_point = get_vp()
	view_point.x = stepify(view_point.x, spacing)
	view_point.z = stepify(view_point.z, spacing)
	
	thread.start(self, "generate", view_point)

func finish_generating():
	var arr = thread.wait_to_finish()
	
	if(arr.size() > pool_size):
		pool_size += (arr.size() - pool_size) * 2
		print("Set max ", name, " count to ", pool_size)
		
		multimesh.set_instance_count(pool_size)
		if(has_lod):
			lod_multimesh.multimesh.set_instance_count(pool_size)
	
	var cam_pos = get_viewport().get_camera().get_global_transform().origin
	
	var i = 0
	if(has_lod):
		var new_arr = []
		var lod_arr = []
		
		while(i < arr.size()):
			var tp = view_point + arr[i].origin
			tp -= cam_pos
			var d = Vector2(tp.x, tp.z).length()
			if(d < lod_dist):
				new_arr.append(arr[i])
			else:
				lod_arr.append(arr[i])
			i += 1
		i = 0
		while(i < pool_size):
			if(i < new_arr.size()):
				multimesh.set_instance_transform(i, new_arr[i])
			else:
				multimesh.set_instance_transform(i, hidden_transform)
			if(i < lod_arr.size()):
				lod_multimesh.multimesh.set_instance_transform(i, lod_arr[i])
			else:
				lod_multimesh.multimesh.set_instance_transform(i, hidden_transform)
			i += 1
	else:
		i = 0
		while(i < pool_size):
			if(i < arr.size()):
				multimesh.set_instance_transform(i, arr[i])
			else:
				multimesh.set_instance_transform(i, hidden_transform)
			i += 1
	
	
	# Add collision shapes to $Collider
	if(has_collider):
		i = 0
		# Disable all collision shapes at first
		while(i < $Collider.get_child_count()):
			var cs = $Collider.get_child(i)
			cs.transform = hidden_transform
			cs.disabled = true
			cs.hide()
			i += 1
		i = 0
		while(i < arr.size()):
			
			# Add a new CollisionShape to pool
			if(i >= $Collider.get_child_count()):
				if(verbose):
					print("Increase ",name, " collision shape count to ", i + 1)
				var new_cs = CollisionShape.new()
				new_cs.set_shape(col_shape)
				new_cs.transform = arr[i]
				$Collider.add_child(new_cs, true)
			
			# Enable shape and set it's transform
			var cs = $Collider.get_child(i)
			cs.transform = arr[i]
			cs.disabled = false
			cs.show()
			i += 1
	
	
	
	
	gen_time = OS.get_ticks_msec() - gen_time
	if(verbose or gen_time >= 2000.0):
		print(name," x ", arr.size()," in ", gen_time / 1000.0, " s")
	transform.origin = view_point
	last_point = view_point
	set_process(true)

func generate(userdata):
	
	var pos = userdata
	var arr = []
	
	pos.x = stepify(pos.x, spacing)
	pos.z = stepify(pos.z, spacing)
	
	var w = stepify(float(view_distance), spacing)
	var x = -w
	while(x < w):
		var z = -w
		while(z < w):
			
			var xx = x + pos.x
			var zz = z + pos.z
			
			var r = noise._noise.get_noise_2d(xx * 123.0 / area_size, zz * 123.0 / area_size) / 2.0 + 0.5
#			var tres_noise = 0.5 +  r
			
			if(r >= area_treshold):
				var rp = Vector3(r, 0.0, 0.0)
				
				r = noise._noise.get_noise_2d(xx * 1234.0, zz * 1234.0) / 2.0 + 0.5
				if(r >= treshold):
					
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
#						print(dif)
						
						if(dif >= slope_min && dif <= slope_max):
							var p = Vector3(xx - pos.x, y, zz  - pos.z)
							
							# Randomize scale
							var s = sin(noise._noise.get_noise_2d((xx) * 1000.0 + (zz) * 1000.0, 0.0) * 100.0)
							s = base_scale + (s * random_scale)
#							print(base_scale)
							
							# Create transform
							var ya = r * 100.0
							var xa = -difz / 7.0
							var za = difx / 7.0
#							var tr = Transform(transform.basis.rotated(Vector3(0,1,0), ya), p / s).scaled(Vector3(s, s, s))
							var tr = Transform.IDENTITY.rotated(Vector3(0,1,0), ya)
							
							if(align_with_ground):
								var quat = Quat(tr.basis)
								quat.set_euler(Vector3(xa, 0.0, za))
								quat = Quat(Basis(quat).y, ya)
								tr.basis = Basis(quat);
							
							tr.basis = tr.basis.scaled(Vector3(s, s, s))
							tr.origin = p;
							
							
							# Append transform to list
							arr.append(tr)
			
			z += spacing
		x += spacing
	
	call_deferred("finish_generating")
	return arr
