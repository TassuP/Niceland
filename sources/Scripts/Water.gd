extends MeshInstance

var world
var snap_step = 4.0
var use_only_lod = false # TODO

func _ready():
	world = get_parent()
	var s = Globals.ground_size / 1024.0
	$Lod.scale = Vector3(s, 1.0, s) * 2.0
	show()

func _process(delta):
	var cam = get_viewport().get_camera()
	
	# Set position
	global_transform.origin = cam.global_transform.origin
	global_translate(-cam.global_transform.basis.z * 64.0)
	global_transform.origin.y = 0.0
	global_transform.origin.x = stepify(global_transform.origin.x, snap_step)
	global_transform.origin.z = stepify(global_transform.origin.z, snap_step)
	

func set_water_colors(water_color, foam_color, horizon_color):
	material_override.set_shader_param("water_color", water_color)
	material_override.set_shader_param("foam_color", foam_color.linear_interpolate(Color.white, 0.2))
	$Lod.material_override.set_shader_param("water_color", foam_color)
	$Lod.material_override.set_shader_param("horizon_color", horizon_color)
	$Lod.material_override.set_shader_param("far", get_viewport().get_camera().far)
