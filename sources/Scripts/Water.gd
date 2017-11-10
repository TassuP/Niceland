extends MeshInstance

var uv_offset = Vector3(0,0,0)
var uv_add = Vector3(0,0,0)
var mat


func _ready():
	mat = get_material_override()

func _process(delta):
	
	# Position
	set_as_toplevel(true)
	var tr = get_global_transform()
	tr.origin = get_parent().get_translation()
	tr.origin.y = Height_Main.water_level
	set_global_transform(tr)
	
	# UV offset
	var uvscale = mat.get_uv1_scale()
	uv_offset = Vector3(-tr.origin.x, -tr.origin.z, 0.0) / 2.0
	uv_offset.x *= uvscale.x
	uv_offset.y *= uvscale.y
	uv_offset.x /= get_scale().x
	uv_offset.y /= get_scale().z
	uv_add += Vector3(1,0,0) * delta * 0.25
	mat.set_uv1_offset(uv_offset + uv_add)
