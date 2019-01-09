extends MeshInstance

export (NodePath) var sun # Directional light for the sun
var use_only_lod = false # Not used

func _ready():
	sun = get_node(sun)

func _process(delta):
	call_deferred("follow_camera")

func follow_camera():
	var cam = get_viewport().get_camera()
	transform = cam.global_transform
	translate(Vector3(0.0, 0.0, 8.0 - cam.far))
	scale = Vector3(cam.far * 4.0, cam.far * 3.0, 1.0)
	material_override.set_shader_param("camera_y", cam.global_transform.origin.y)
	material_override.set_shader_param("sun_dir", sun.global_transform.basis.z)
	
func set_cloud_colors(cloud_color, lining_color, horizon_color):
	material_override.set_shader_param("cloud_color", cloud_color)
	material_override.set_shader_param("lining_color", lining_color)
	material_override.set_shader_param("horizon_color", horizon_color)

func set_cloudiness(cloudiness):
	material_override.set_shader_param("cloudiness", cloudiness)