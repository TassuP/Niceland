extends Node

var _noise

func init():
	_noise = make_noise()

func make_noise():
	_noise = OpenSimplexNoise.new()
	_noise.seed = Globals.game_seed
	_noise.octaves = 6
	_noise.period = 1024 * Globals.ground_xz_scale
	_noise.persistence = 0.4
	_noise.lacunarity = 2.5
	return _noise

func get_n(pos):
	return _noise.get_noise_2d(pos.x, pos.z)

func get_h(pos):
	pos.y = _noise.get_noise_2d(pos.x, pos.z)
	pos.y *= 0.1 + pos.y * pos.y
	pos.y *= 1024.0
	pos.y += 32.0
	if(pos.y <= 0.2):
		pos.y -= 1.0
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

