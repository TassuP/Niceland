extends Polygon2D

export (NodePath) var target
export var rotate = false
var map
var sz

func _ready():
	target = get_node(target)
	map = get_parent().get_node("Map")
	sz = get_parent().rect_size
	

func _process(delta):
	var tpos = target.get_global_transform().origin
	tpos -= map.viewpoint.get_global_transform().origin
	tpos = Vector2(tpos.x, tpos.z)
	position = sz / 2.0 + tpos / map.zoom
	
	if(rotate):
		set_rotation(-target.rotation.y)
	
