extends Spatial

export (NodePath) var box
export (NodePath) var aimbox
export (NodePath) var smallbox
var aimboxpos

func _ready():
	box = get_node(box)
	aimbox = get_node(aimbox)
	smallbox = get_node(smallbox)
	box.set_as_toplevel(true)
	smallbox.set_as_toplevel(true)
	
	aimboxpos = aimbox.transform.origin

func snap(p):
	p.x = stepify(p.x, 2.0)
#	p.y = stepify(p.y, 2.0)
	p.z = stepify(p.z, 2.0)
	return p

func _process(delta):
	
	# Shoot box
	if(Input.is_action_just_pressed("shoot")):
		var newbox = smallbox.duplicate()
		newbox.set_mode(RigidBody.MODE_RIGID)
		add_child(newbox)
		newbox.global_transform = global_transform
		newbox.linear_velocity = -get_parent().transform.basis.z * 20.0
		newbox.set_as_toplevel(true)
		
	# Place box
	if(Input.is_action_pressed("plot")):
		aimbox.show()
		aimbox.transform.origin = aimboxpos
		aimbox.global_transform.origin = snap(aimbox.global_transform.origin)
	else:
		aimbox.hide()
	if(Input.is_action_just_released("plot")):
		var newbox = box.duplicate()
		newbox.set_mode(RigidBody.MODE_RIGID)
		add_child(newbox)
		newbox.global_transform = aimbox.global_transform
		newbox.linear_velocity = Vector3(0,0,0) # get_parent().transform.basis.y * 3.0
		newbox.set_as_toplevel(true)