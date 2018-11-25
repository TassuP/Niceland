extends Camera

export(bool) var invert_mouse = true
var speed = 12.0
var world
var target_trans = Spatial.new()
var noise

# Functions 'make_noise' and 'get_h' should be copied to
# other scripts that need the same height data.
func make_noise(_seed):
	var noise = OpenSimplexNoise.new()
	noise.seed = _seed
	noise.octaves = 6
	noise.period = 1024 * 2.0
	noise.persistence = 0.4
	noise.lacunarity = 2.5
	return noise
func get_h(noise, pos):
	pos.y = noise.get_noise_2d(pos.x, pos.z)
	pos.y *= 0.1 + pos.y * pos.y
	pos.y *= 1024.0
	# Make waterlines nicer
	pos.y += 5.0
	if(pos.y <= 0.2):
		pos.y -= 1.0
	else:
		pos.y += 0.2
	return pos.y

func _ready():
	target_trans.transform = transform
	world = get_parent()
	noise = make_noise(world.game_seed)
	get_viewport().get_camera().far = world.ground_size
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$"Map symbol".show()

func _physics_process(delta):
	
	var spd = speed * delta
	
	var h =  get_h(noise, transform.origin)
	if(Input.is_key_pressed(KEY_SHIFT)):
		spd *= 5.0
	else:
		target_trans.transform.origin.y = h + 3
	
	if(target_trans.transform.origin.y <= h + 1):
		target_trans.transform.origin.y = h + 1
		
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
