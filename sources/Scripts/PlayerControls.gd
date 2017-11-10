extends Node

export(NodePath) var plr
export(NodePath) var cam
export(NodePath) var ray_down

export (float) var mouse_smooth = 0.5
export (float) var mouse_speed = 0.004

export (float) var move_smooth = 0.1
export (float) var move_speed = 30.0

var rotate_view = Vector2(0,0)
var view_rotation = Vector2(0,0)
var target_rotation = Vector2(0,0)
var move_dir = Vector3(0,0,0)
var move_vec = Vector3(0,0,0)

var player_height = 1.5
var ground_y = 0.0
var is_grounded = false
var is_swimming = false
var grounding_treshold = 0.2
var fall_speed = 0.0

var lift = false
var skip_mousemove = 0
#var terrain_type

func _ready():
	plr = get_node(plr)
	cam = get_node(cam)
	ray_down = get_node(ray_down)
	
	# Let's not start the game in the middle of the ocean
	plr.set_translation(Height_Main.find_land(plr.get_translation()))
	
	# Land player to ground
	var tr = plr.get_global_transform()
	if(GameSettings.plr_transform != null):
		tr = GameSettings.plr_transform
	tr.origin.y = get_ground_y(tr.origin) + player_height
	plr.set_global_transform(tr)
	
	set_process_input(true)
	set_physics_process(true)

func _physics_process(delta):
	if(GameSettings.paused):
		return
	
	mouselook(delta)
	keyboard_walking(delta)
	
	if(!Input.is_mouse_button_pressed(BUTTON_RIGHT) || !GameSettings.dev_mode):
		player_grounding(delta)
		GameSettings.hold_generating = false
	else:
		fall_speed = 0.0
		is_grounded = false
		GameSettings.hold_generating = true
	
func mouselook(delta):
	target_rotation.x += rotate_view.x * mouse_speed
	target_rotation.y += rotate_view.y * mouse_speed
	rotate_view = Vector2(0, 0)
	
	if(mouse_smooth <= 0):
		view_rotation = target_rotation
	else:
		var l = lerp(10.0, 1.0, mouse_smooth) * delta
		view_rotation = view_rotation.linear_interpolate(target_rotation, l)
	
	plr.set_rotation(Vector3(0, -view_rotation.x, 0))
	if(GameSettings.invert_mouse):
		cam.set_rotation(Vector3(view_rotation.y, 0, 0))
	else:
		cam.set_rotation(Vector3(-view_rotation.y, 0, 0))


func player_grounding(delta):
	var tr = plr.get_transform()
	ground_y = get_ground_y(tr.origin)
	
	# Is touching ground
	is_grounded = plr.is_on_floor()
	
	# Keep above ground
	if(ground_y >= (tr.origin.y - player_height) - grounding_treshold):
		tr.origin.y = ground_y + player_height
		plr.set_transform(tr)
		is_grounded = true
	
	# Is under water
	is_swimming = false
	if(Height_Main.water_level >= (tr.origin.y - player_height * 0.75)):
		is_swimming = true
	
	if(is_grounded):
		# Stick to ground
#		tr.origin.y = ground_y + player_height
		fall_speed = 0.0
#		plr.set_transform(tr)
	else:
		# Swimming
		if(is_swimming):
			fall_speed = lerp(fall_speed, 0.0, delta)
		else:
		# Falling
			fall_speed += delta

func get_ground_y(pos):
	if(ray_down.is_colliding()):
		return ray_down.get_collision_point().y
	else:
		return Height_Main.gen(pos.x, pos.z, false, true)	

func keyboard_walking(delta):
	var basis = cam.get_global_transform().basis
	var new_vec = ((basis.x * move_dir.x) + (basis.y * move_dir.y) + (basis.z * move_dir.z)) * move_speed
	move_dir.y = -fall_speed
	move_vec = move_vec.linear_interpolate(new_vec, clamp(delta / move_smooth, 0.0, 1.0))
	
	move_vec = plr.move_and_slide(move_vec, Vector3(0,1,0), 10.0, 4, 45)
	
	if(GameSettings.dev_mode):
		if(Input.is_mouse_button_pressed(BUTTON_RIGHT)):
			plr.global_translate(move_vec * delta * 5)

func _input(event):
	
	#############  Mouse mode  #################
	if(GameSettings.paused):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	#################  Mouse  ##################
	if (event is InputEventMouseMotion):
		rotate_view = event.relative
	
	################  Keyboard  ################
	if(Input.is_key_pressed(KEY_A)):
		move_dir.x = -1.0
	if((!Input.is_key_pressed(KEY_A) && move_dir.x==-1.0)):
		move_dir.x = 0.0
	if(Input.is_key_pressed(KEY_D)):
		move_dir.x = 1.0
	if((!Input.is_key_pressed(KEY_D) && move_dir.x==1.0)):
		move_dir.x = 0.0
	if(Input.is_key_pressed(KEY_W)):
		move_dir.z = -1.0
	if((!Input.is_key_pressed(KEY_W) && move_dir.z==-1.0)):
		move_dir.z = 0.0
	if(Input.is_key_pressed(KEY_S)):
		move_dir.z = 1.0
	if((!Input.is_key_pressed(KEY_S) && move_dir.z==1.0)):
		move_dir.z = 0.0
#	if(event.is_action_pressed("ui_left")):
#		move_dir.x = -1.0
#	if(event.is_action_released("ui_left")):
#		move_dir.x = 0.0
#	if(event.is_action_pressed("ui_right")):
#		move_dir.x = 1.0
#	if(event.is_action_released("ui_right")):
#		move_dir.x = 0.0
#	if(event.is_action_pressed("ui_up")):
#		move_dir.z = -1.0
#	if(event.is_action_released("ui_up")):
#		move_dir.z = 0.0
#	if(event.is_action_pressed("ui_down")):
#		move_dir.z = 1.0
#	if(event.is_action_released("ui_down")):
#		move_dir.z = 0.0
	if(GameSettings.dev_mode):
		if(Input.is_mouse_button_pressed(BUTTON_RIGHT)):
			if(event.is_action("scroll_up")):
				move_dir.y = 4
			if(event.is_action("scroll_down")):
				move_dir.y = -4

func teleport():
	print("Teleport")
	var to = Height_Main.find_land(Vector3(randf(), 0, randf()) * 5000.0)
	GameSettings.teleport(to)
