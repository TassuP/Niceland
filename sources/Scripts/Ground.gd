extends MeshInstance

export var use_radial_grid = true
export var generate_collider = true

var noise = preload("res://Scripts/HeightGenerator.gd").new()

var use_threading = true
var thread = Thread.new()
var gen_verts = []
var view_point
var last_point
var gen_time

var near_far_limit_i = -1
var upd_distance = 16

func _ready():
	
	noise.init()
	
	if(generate_collider):
		var sb = StaticBody.new()
		var cs = CollisionShape.new()
		sb.name = "StaticBody"
		cs.name = "CollisionShape"
		sb.add_child(cs)
		add_child(sb)
	
	set_process(false)
	
	upd_distance = float(Globals.ground_size) / 16.0
	
	view_point = get_vp()
	last_point = view_point
	
	init_genverts()
	
	# First round of generating
	var temp = use_threading
	use_threading = false
	start_generating()
	use_threading = temp
#
#	call_deferred("start_generating")

func get_vp():
	var p = get_viewport().get_camera().get_global_transform().origin
	p -= get_viewport().get_camera().get_global_transform().basis.z * upd_distance * 0.75
	p.y = 0.0
	return p

func _process(delta):
	view_point = get_viewport().get_camera().get_global_transform().origin
	view_point.y = 0.0
	if(last_point.distance_to(view_point) > upd_distance):
		start_generating()
	
	

func start_generating():
#	print("Start generating ground")
	gen_time = OS.get_ticks_msec()
	set_process(false)
	view_point = get_vp()
	view_point.x = stepify(view_point.x, Globals.ground_lod_step)
	view_point.z = stepify(view_point.z, Globals.ground_lod_step)
	
	if(use_threading):
		thread.start(self, "generate", [view_point, noise])
	else:
		finish_generating()

func finish_generating():
	var msh
	if(use_threading):
		msh = thread.wait_to_finish()
	else:
		msh = generate([view_point, noise])
	self.set_mesh(msh)
	
	gen_time = OS.get_ticks_msec() - gen_time
	print("Ground generated in ", gen_time / 1000.0, " s")
	transform.origin = view_point
	last_point = view_point
	
	if(Globals.generate_just_once == false):
		set_process(true)
	

func generate(userdata):
	
	var pos = userdata[0]
	var surf = SurfaceTool.new()
	
	# Generate surface
	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	surf.add_smooth_group(true)
	var i = 0
	while(i < gen_verts.size()):
		
		# Generate vertex position
		var p = gen_verts[i] + pos
		p.y = noise.get_h(p)
		
		# Generate UV
		if(i < near_far_limit_i):
			# Texture tiles less when far
			surf.add_uv(Vector2(p.x, p.z) / 8.0)
			surf.add_uv2(Vector2(p.x, p.z) / 8.0)
		else:
			# Texture tiles more when near
			surf.add_uv(Vector2(p.x, p.z))
			surf.add_uv2(Vector2(p.x, p.z))
		
		surf.add_vertex(Vector3(gen_verts[i].x, p.y, gen_verts[i].z))
		i += 1
	surf.generate_normals()
	surf.index()
	
	# SurfaceTool to Mesh
	var msh = Mesh.new()
	msh = surf.commit()
	
	# Collider
	if(generate_collider):
		var shp = msh.create_trimesh_shape()
		$StaticBody/CollisionShape.call_deferred("set_shape", shp)
	
	if(use_threading):
		call_deferred("finish_generating")
	return msh

func init_genverts():
	var pi = 3.141592654
	var pi2 = pi*2.0
	var small_step = max(Globals.ground_lod_step / 8.0, 2.0)
	var a = (360.0 / (360.0 / small_step)) / 57.295779515
	
	# Radial web
	var x = 0.0
	if(use_radial_grid == true):
		while(x < pi2):
			var s = small_step
			var z = Globals.ground_size / 10.0 - Globals.ground_lod_step
			while(z <= Globals.ground_size):
				
				var z1 = z
				var z2 = z + s
				
				var p1 = Vector3(z1, 0.0, z1)
				var p2 = Vector3(z1, 0.0, z1)
				var p3 = Vector3(z2, 0.0, z2)
				var p4 = Vector3(z2, 0.0, z2)
				
				p1.x *= sin(x)
				p1.z *= cos(x)
				
				p2.x *= sin(x + a)
				p2.z *= cos(x + a)
				
				p3.x *= sin(x + a)
				p3.z *= cos(x + a)
				
				p4.x *= sin(x)
				p4.z *= cos(x)
				
				# Stepifying slightly helps with jumps between lods
				p1.x = stepify(p1.x, Globals.ground_lod_step)
				p1.z = stepify(p1.z, Globals.ground_lod_step)
				p2.x = stepify(p2.x, Globals.ground_lod_step)
				p2.z = stepify(p2.z, Globals.ground_lod_step)
				p3.x = stepify(p3.x, Globals.ground_lod_step)
				p3.z = stepify(p3.z, Globals.ground_lod_step)
				p4.x = stepify(p4.x, Globals.ground_lod_step)
				p4.z = stepify(p4.z, Globals.ground_lod_step)
				
				gen_verts.append(p1)
				gen_verts.append(p2)
				gen_verts.append(p3)
	
				gen_verts.append(p3)
				gen_verts.append(p4)
				gen_verts.append(p1)
				
				z += s
	#			s *= 2.0
				s += Globals.ground_lod_step * 2.0
				
			x += a
		
		near_far_limit_i = gen_verts.size()
	
	# Square grid
	var s = Globals.ground_lod_step# * 4.0
	var w = Globals.ground_size + s
	
	if(use_radial_grid == true):
		w = Globals.ground_size / 10.0 + s
	
	x = -w
	while(x < w):
		var z = -w
		while(z < w):
			if(Vector3(x,0,z).length() <= w):
				var p1 = Vector3(x, 0.0, z)
				var p2 = Vector3(x+s, 0.0, z)
				var p3 = Vector3(x+s, 0.0, z+s)
				var p4 = Vector3(x, 0.0, z+s)
				
				gen_verts.append(p1)
				gen_verts.append(p2)
				gen_verts.append(p3)
				
				gen_verts.append(p3)
				gen_verts.append(p4)
				gen_verts.append(p1)
			
			z += s
		x += s
		
	print("Ground tris = ",gen_verts.size() / 3.0)


