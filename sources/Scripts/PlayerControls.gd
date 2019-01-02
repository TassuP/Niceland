extends KinematicBody

export(bool) var invert_mouse = true

var max_speed = 30.0
var acceleration = 60.0
var decceleration = 5.0
var mouse_speed = 0.003
var mouse_smooth = 0.15

var gravity = Vector3(0, -30, 0)
var mv = Vector3(0,0,0)

var rotator_x = Spatial.new()
var rotator_y = Spatial.new()

var noise = preload("res://Scripts/HeightGenerator.gd").new()

func _ready():
	noise.init()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	var h =  noise.get_h(transform.origin)
	if(transform.origin.y < h + 5.0):
		transform.origin.y = h + 5.0

func _process(delta):
	
	var dec = true
	
	# WASD
	if(Input.is_action_pressed("move_forward")):
		mv -= transform.basis.z * acceleration * delta
		dec = false
	if(Input.is_action_pressed("move_backward")):
		mv += transform.basis.z * acceleration * delta
		dec = false
	if(Input.is_action_pressed("move_left")):
		mv -= transform.basis.x * acceleration * delta
		dec = false
	if(Input.is_action_pressed("move_right")):
		mv += transform.basis.x * acceleration * delta
		dec = false
	
	# Wheel
	if(Input.is_action_just_released("ui_scroll_up")):
		mv += transform.basis.y * acceleration * delta
	if(Input.is_action_just_released("ui_scroll_down")):
		mv -= transform.basis.y * acceleration * delta
	
	# Decceleration
	if(dec):
		mv = mv.linear_interpolate(Vector3(0, mv.y, 0), decceleration * delta)
	
	# Apply gravity
	mv += gravity * delta
	
	# Max speed
	if(mv.length() > max_speed):
		mv = mv.normalized() * max_speed
	
	# Apply movement
	mv = move_and_slide(mv, Vector3(0,1,0), 0.05, 4, deg2rad(40.0))
	
	# Smooth apply rotation
	rotator_x.transform.origin = $Camera.transform.origin
	rotator_y.transform.origin = transform.origin
	transform = transform.interpolate_with(rotator_y.transform, clamp(delta / mouse_smooth, 0.0, 1.0))
	$Camera.transform = $Camera.transform.interpolate_with(rotator_x.transform, clamp(delta / mouse_smooth, 0.0, 1.0))
	


func _input(event):
	
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_Y:
			invert_mouse = !invert_mouse
	
	# Mouselook
	if (event is InputEventMouseMotion):
		var mm = event.relative * mouse_speed
		
		rotator_y.rotate_y(-mm.x)
		
		if(invert_mouse):
			rotator_x.rotate_x(mm.y)
		else:
			rotator_x.rotate_x(-mm.y)
