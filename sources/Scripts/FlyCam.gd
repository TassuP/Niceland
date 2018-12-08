extends Camera

export(bool) var invert_mouse = true
var speed = 12.0
var world
var target_trans = Spatial.new()

var noise = preload("res://Scripts/HeightGenerator.gd").new()

func _ready():
	target_trans.transform = transform
	world = get_parent()
	noise.init()
	get_viewport().get_camera().far = Globals.ground_size
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$"Map symbol".show()

func _physics_process(delta):
	
	var spd = speed * delta
	
	var h =  noise.get_h(transform.origin)
	if(Input.is_key_pressed(KEY_SHIFT)):
		spd *= 15.0
	else:
		target_trans.transform.origin.y = h + 3
	
		
	# WASD
	if(Input.is_key_pressed(KEY_W)):
		target_trans.translate(Vector3(0.0, 0.0, -1.0) * spd)
	if(Input.is_key_pressed(KEY_S)):
		target_trans.translate(Vector3(0.0, 0.0, 1.0) * spd)
	if(Input.is_key_pressed(KEY_A)):
		target_trans.translate(Vector3(-1.0, 0.0, 0.0) * spd)
	if(Input.is_key_pressed(KEY_D)):
		target_trans.translate(Vector3(1.0, 0.0, 0.0) * spd)
	
	# Smooth apply
	transform = transform.interpolate_with(target_trans.transform, clamp(delta * 2.0, 0.0, 1.0))
	
	# Keep above ground
	if(transform.origin.y < h + 3):
		transform.origin.y = h + 3
	
	# Teleport
	if(Input.is_key_pressed(KEY_T)):
		var r = target_trans.transform.origin
		r.x = (randf() - randf()) * 100000.0
		r.z = (randf() - randf()) * 100000.0
		target_trans.transform.origin += r

func _input(event):
	# Mouselook
	if (event is InputEventMouseMotion):
		var mm = event.relative / 200.0
		target_trans.transform.basis = target_trans.transform.basis.orthonormalized()
		
		target_trans.rotate(Vector3(0,1,0), -mm.x)
		if(invert_mouse):
			target_trans.rotate(target_trans.transform.basis.x, mm.y)
		else:
			target_trans.rotate(target_trans.transform.basis.x, -mm.y)
