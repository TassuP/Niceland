extends MeshInstance

# Terrain settings
export var enabled = true
export var use_threading = true
export var smooth_shading = true
export var smooth_colors = true
export var wireframe = false
export(NodePath) var plr
export(NodePath) var col

var patch_size_min = 2048 / 4
var patch_size_max = 4096
var patch_size
var obj_dist = 100
var uv_tiling = 0.025
var upd_distance = 100
var step = 1.0
var offset
var offset2
var thread
var surf
var m_mesh
var col_shape

var gen_point = Vector3(0,0,0)

var highest_peak = 0.0
var lowest_notch = 0.0

var gen_verts = []

var m_uv = []
var m_colors = []
var m_verts = []
var m_seams = []

var obj_plotters = []

var last_gen_time = 0
var terrain_changed = false

var cancel = false

func _ready():
	
	if(!enabled):
		set_process(false)
		return
	
	plr = get_node(plr)
	col = get_node(col)
	
	obj_plotters = get_tree().get_nodes_in_group("Plotters")
	
	
	# Setup level of detail
	step = 2.0 # round(lerp(4.0, 2.0, GameSettings.geometry_level))
	patch_size = stepify(lerp(patch_size_min, patch_size_max, GameSettings.geometry_level), step)
	
	obj_dist = stepify(patch_size / 16, step)
	upd_distance = obj_dist / 8.0
	
	GameSettings.terrain_size = patch_size
	Height_Terrain.step = step
	
#	print("patch_size ",patch_size)
#	print("upd_distance ",upd_distance)
#	print("obj_dist ",obj_dist)
#	print("step ",step)
	
	offset2 = Vector3(patch_size/2.0, 0, patch_size/2.0)
	
	init_genverts()
	
	surf = SurfaceTool.new()
	m_mesh = Mesh.new()
	col_shape = ConcavePolygonShape.new()
	
	if(use_threading):
		thread = Thread.new()
	set_process(false)
	
	# Generate first round without threading
	var plr_pos = plr.get_global_transform().origin
	plr_pos.y = 0.0
	gen_point = plr_pos # plr.get_translation()
	gen_point.x = stepify(gen_point.x,step)
	gen_point.y = 0.0
	gen_point.z = stepify(gen_point.z,step)
	call_deferred("generate", null)

func _process(delta):
	
	# Don't do anything while flying
	if(GameSettings.hold_generating):
		return
	
	GameSettings.terrain_generation_time = last_gen_time
		
	if(terrain_changed):
		terrain_changed = false
		var i = 0
		while(i < obj_plotters.size()):
			
			obj_plotters[i].do_landing_again()
			
			i += 1
		
	
#	var plr_pos = plr.get_global_transform().origin
	var plr_pos = get_viewport().get_camera().get_global_transform().origin
	plr_pos.y = 0.0
	if(plr_pos.distance_to(gen_point) > upd_distance):
		
		# Center to player
		gen_point = plr_pos # plr.get_translation()
		gen_point.x = stepify(gen_point.x,step)
		gen_point.y = 0.0
		gen_point.z = stepify(gen_point.z,step)

		if(use_threading):
			if(thread.is_active()):
				thread.wait_to_finish()
			thread.start(self,"generate")
		else:
			generate(null)

func init_genverts2():
	var pi = 3.141592654
	var pi2 = pi*2.0
	
	var a = (360.0 / (180.0 / step)) / 57.295779515
	
	var x = 0.0
	while(x < pi2):
		var s = step / 2.0
		var z = 0.0
		while(z <= patch_size):
			
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
			
			gen_verts.append(p1)
			gen_verts.append(p2)
			gen_verts.append(p3)
			
			gen_verts.append(p3)
			gen_verts.append(p4)
			gen_verts.append(p1)
			
			z += s
			if(s > patch_size / 8.0):
				s *= 2.0
			s += step
		x += a
	print("Terrain verts = ",gen_verts.size())
	
func init_genverts():
	var pi = 3.141592654
	var pi2 = pi*2.0
	
	var a = (360.0 / (360.0 / step)) / 57.295779515
	
	# Radial web
	var x = 0.0
	while(x < pi2):
		var s = step
		var z = patch_size / 10.0 - step
		while(z <= patch_size):
			
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
			
			gen_verts.append(p1)
			gen_verts.append(p2)
			gen_verts.append(p3)

			gen_verts.append(p3)
			gen_verts.append(p4)
			gen_verts.append(p1)
			
			z += s
#			s *= 2.0
			s += step # * 2.0
			
		x += a
		
	# Square grid
	var s = step * 4.0
	var w = patch_size / 10.0 + s
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
		
	print("Terrain tris = ",gen_verts.size() / 3.0)

func generate(userdata):
	set_process(false)
	print("Generating terrain")
	
	cancel = false
	
	var start_time = OS.get_ticks_msec()
	
	m_uv.clear()
	m_colors.clear()
	m_verts.clear()
	m_seams.clear()
	
	highest_peak = -9999.0
	lowest_notch = 9999.0
	
	var i = 0
	while(i < gen_verts.size()):
		if(cancel):
			return
		process_point(i)
		i += 1
	create_mesh()
	
	var end_time = OS.get_ticks_msec()
	var total_time = end_time - start_time
	last_gen_time = total_time
	
	set_process(true)
	terrain_changed = true
	print("Terrain generated in ", total_time / 1000.0, " sec")

func create_mesh():
	
	# SurfaceTool
	surf.clear()
	if(wireframe == true):
		surf.begin(Mesh.PRIMITIVE_LINES)
	else:
		surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	if(smooth_shading):
		surf.add_smooth_group(true)
	
	var i = 0
	var ii = 0
	while(i < m_verts.size()):
		surf.add_uv(m_uv[i])
		
		if(smooth_colors):
			surf.add_color(m_colors[i])
		else:
			if(ii == 0):
				surf.add_color(m_colors[i])
			ii += 1
			if(ii >= 6):
				ii = 0
		surf.add_vertex(m_verts[i])
		
		if(cancel):
			return
			
		i += 1
	
	surf.generate_normals()
	surf.index()
	
	# SurfaceTool to Mesh
	m_mesh = surf.commit()
	self.set_mesh(m_mesh)
	set_translation(gen_point)
	
	# Generate collider
	col_shape.set_faces(m_mesh.get_faces())
	col.set_shape(col_shape)
	col.set_disabled(false)
	col.set_translation(gen_point)

func process_point(i):
	var p = gen_verts[i]
#	p.x = stepify(p.x, step / 2.0)
#	p.z = stepify(p.z, step / 2.0)
	p.y = Height_Terrain.gen(gen_point.x + p.x, gen_point.z + p.z, false, true)
	
	if(p.y > highest_peak):
		highest_peak = p.y
	if(p.y < lowest_notch):
		lowest_notch = p.y
	
	var c = gen_vertex_color(p + gen_point)
	
	var uv = Vector2(p.x, p.z)
	uv.x += gen_point.x - floor(gen_point.x)
	uv.y += gen_point.z - floor(gen_point.z)
	uv *= uv_tiling
#	var uv = Vector2(p.x, p.z) * uv_tiling
	m_uv.append(uv)
	m_colors.append(c)
	m_verts.append(p)

func gen_vertex_color(v):
	var t = Height_Terrain.gen(v.x, v.z, true, true)
	if(t == Height_Terrain.TerrainType.plains):
		return Color(0, 0.5, 0)
	if(t == Height_Terrain.TerrainType.hill):
		return Color(0, 1.0, 0)
	if(t == Height_Terrain.TerrainType.swamp):
		return Color(0.5, 0, 0)
	if(t == Height_Terrain.TerrainType.mountain):
		return Color(1.0, 0, 0)
	if(t == Height_Terrain.TerrainType.snow):
		return Color(1, 1, 1)
	if(t == Height_Terrain.TerrainType.lake):
		return Color(0, 0, 0.5)
	if(t == Height_Terrain.TerrainType.ocean):
		return Color(0, 0, 1.0)

	# Not defined!!!
	return Color(1,0,1)
	

