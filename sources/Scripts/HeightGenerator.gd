extends Node

var _noise

func init(world = null):
	if(world == null):
		_noise = make_noise()
	else:
		_noise = make_noise(world.game_seed, world.ground_xz_scale)

func make_noise(_seed = 0, stretch = 2.0):
#	print(_seed)
	_noise = OpenSimplexNoise.new()
	# BUG: Minimap gets a corrupted seed
	_noise.seed = 0 #_seed
	_noise.octaves = 6
	_noise.period = 1024 * stretch
	_noise.persistence = 0.4
	_noise.lacunarity = 2.5
	return _noise

func get_h(pos):
	pos.y = _noise.get_noise_2d(pos.x, pos.z)
	pos.y *= 0.1 + pos.y * pos.y
	pos.y *= 1024.0
	# Make waterlines nicer
#	pos.y += 5.0
	pos.y += 32.0
	if(pos.y <= 0.2):
		pos.y -= 1.0
	else:
		pos.y += 0.2
	return pos.y

