extends MultiMeshInstance

# World node is optional
export (NodePath) var world

# If the world node is found, then the following variables
# will be copied from there.
var game_seed = 0
var ground_size = 1024 * 2
var ground_lod_step = 4.0

var thread = Thread.new()
var gen_verts = []
var view_point
var last_point
var gen_time

var near_far_limit_i = 0
var upd_distance = 16

# Functions 'make_noise' and 'get_h' should be copied to
# other scripts that need the same height data.
func make_noise(_seed):
	var noise = SimplexNoise.new()
	noise.seed = _seed
	noise.octaves = 6
	noise.period = 1024
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

	if(world != null):
		print("Copying ground object settings from World")
		world = get_node(world)
		game_seed = world.game_seed
		ground_size = world.ground_size
		ground_lod_step = world.ground_lod_step
	else:
		print("Using default settings for ground objects")

	set_process(false)

	upd_distance = float(ground_size) / 16.0

	view_point = get_vp()
	last_point = view_point

	call_deferred("start_generating")

func get_vp():
	var p = get_viewport().get_camera().get_global_transform().origin
	p -= get_viewport().get_camera().get_global_transform().basis.z * upd_distance * 0.75
	p.y = 0.0
	return p

func _process(delta):
	view_point = get_viewport().get_camera().get_global_transform().origin
	view_point.y = 0.0
	if(last_point.distance_to(view_point) > upd_distance):
		start_generating()



func start_generating():
	print("Start generating ground objects, seed = ", game_seed)
	gen_time = OS.get_ticks_msec()
	set_process(false)
	view_point = get_vp()
	view_point.x = stepify(view_point.x, ground_lod_step)
	view_point.z = stepify(view_point.z, ground_lod_step)

	thread.start(self, "generate", [view_point, game_seed])

func finish_generating():
	var y = thread.wait_to_finish()

	gen_time = OS.get_ticks_msec() - gen_time
	print("Ground objects generated in ", gen_time, " msec")
	transform.origin = view_point
	transform.origin.y = y
	last_point = view_point
	set_process(true)

func generate(userdata):

	var pos = userdata[0]
	var noise = make_noise(userdata[1])

	var y = get_h(noise, pos)

	call_deferred("finish_generating")
	return y
