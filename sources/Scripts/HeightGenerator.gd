extends Node

var _noise

func init():
	name = "I'm a HeightGenerator"
	_noise = make_noise()

func make_noise():
	_noise = OpenSimplexNoise.new()
	_noise.seed = Globals.game_seed
	_noise.octaves = 6
	_noise.period = 4096.0 * Globals.ground_xz_scale
	_noise.persistence = 0.35
	_noise.lacunarity = 3.0
	return _noise

func get_n(pos):
	return _noise.get_noise_2d(pos.x, pos.z)

func get_h(pos):
	# Base noise
	pos.y = _noise.get_noise_2d(pos.x, pos.z)
	
	# Lift slightly, so there's less water everywhere
	pos.y += 0.1
	
	# Make mountains and flatlands more distinct
	if(pos.y > 0.05):
		pos.y = pow((pos.y - 0.05) * 1.6, 1.5) + 0.05
	
	# Scale everything up
	pos.y *= 512.0
	
	# Make shoreline steeper to avoid z-fighting
	if(pos.y <= 0.0):
		pos.y -= 0.5
	else:
		pos.y += 0.2
	return pos.y

func get_interpolated_h(pos):
	
	var x1 = stepify(pos.x, Globals.ground_lod_step)
	var z1 = stepify(pos.z, Globals.ground_lod_step)
	var x2 = x1 + Globals.ground_lod_step
	var z2 = z1 + Globals.ground_lod_step
	
	var h1 = get_h(Vector3(x1, 0.0, z1))
	var h2 = get_h(Vector3(x2, 0.0, z1))
	var h3 = get_h(Vector3(x1, 0.0, z2))
	var h4 = get_h(Vector3(x2, 0.0, z2))
	
	var px = (pos.x - x1) / Globals.ground_lod_step
	var pz = (pos.z - z1) / Globals.ground_lod_step
	
	var hi1 = lerp(h1, h2, px)
	var hi2 = lerp(h3, h4, px)
	var h = lerp(hi1, hi2, pz)
	
	return h

