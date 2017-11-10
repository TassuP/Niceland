extends Node

var texture_path = "res://terrain.png"
var img
var img_size = Vector2(0,0)
var fractal = true

var horizontal_scale = 0.25
var vertical_scale = 0.5
var water_level = -5.0
var snow_level = 420.0

var step = 1.0 # Calculated in Terrain.gd

var ocean_percent = 0.0
var inland_percent = 0.0
var hill_percent = 0.0
var hill_height_percent = 0.0
var mountain_percent = 0.0
var mountain_height_percent = 0.0

enum TerrainType{
	ocean,
	lake,
	swamp,
	plains,
	hill,
	mountain,
	snow
}
var terrain_type = TerrainType.plains

func get_terrain_type_str(terrain_type):
	if(terrain_type == TerrainType.ocean):
		return "ocean"
	if(terrain_type == TerrainType.lake):
		return "lake"
	if(terrain_type == TerrainType.swamp):
		return "swamp"
	if(terrain_type == TerrainType.plains):
		return "plains"
	if(terrain_type == TerrainType.hill):
		return "hill"
	if(terrain_type == TerrainType.mountain):
		return "mountain"
	if(terrain_type == TerrainType.snow):
		return "snow"
	
func _ready():
	img = Image.new()
	img.load(texture_path)
	img.lock()
	img_size.x = img.get_width()
	img_size.y = img.get_height()


# I need a little help here, please!
func wrap(n, m):
	while(n < 0.0):
		n += m
	while(n >= m):
		n -= m
	return n
#func wrap(x,m):
#	m = int(floor(m))
#	var rem = x - floor(x)
#	x = int(floor(x))
#	return (m + (x%m)%m) + rem
#func wrap(n, m):
#	var x = n
#	var lo = 0.0
#	var hi = m
#	var t = (x-lo) / (hi-lo)
#	return lo + (hi-lo) * (t-floor(t))


func sample_map(x, y, interpolate):
	
	x += img_size.x / 2.0
	y += img_size.y / 2.0
	
	if(interpolate == false):
		var v = img.get_pixel(wrap(x, img_size.x), wrap(y, img_size.y)).r
		return (v-0.5)*2.0
	
	var fx = floor(x)
	var fy = floor(y)
	var cx = x + 1.0
	var cy = y + 1.0
	
	var px = x - fx
	var py = y - fy
	
	var fx_fy = img.get_pixel(wrap(fx, img_size.x), wrap(fy, img_size.y)).r
	
	
	var cx_fy = img.get_pixel(wrap(cx, img_size.x), wrap(fy, img_size.y)).r
	var cx_cy = img.get_pixel(wrap(cx, img_size.x), wrap(cy, img_size.y)).r
	var fx_cy = img.get_pixel(wrap(fx, img_size.x), wrap(cy, img_size.y)).r
	
	var vx1 = lerp(fx_fy, cx_fy, px)
	var vx2 = lerp(fx_cy, cx_cy, px)
	var v = lerp(vx1, vx2, py)
	
	return (v-0.5)*2.0

func randf_pattern(x, z):
	var r = img.get_pixel(wrap(x, img_size.x), wrap(z, img_size.y)).r
	return r

func find_land(from):
	var failsafe = 9999
	var jump = 0
	var cnt = 1
	while(cnt < failsafe):
		var pos = from + Vector3(randf(), 0, randf()) * jump
		var h = gen(pos.x, pos.z, false, false)
		
		if(h > water_level && h < 100.0):
#			print("Found land after ", cnt, " tries")
			return pos
		
		cnt += 1
		jump += 10
	
	print("Couldn't find land")
	return from
	
	
func gen(x, y, get_terrain_type, interpolate):
	
	x /= horizontal_scale
	y /= horizontal_scale
	
	# Use heightmap image without any trickery
	if(fractal == false):
		terrain_type = TerrainType.plains
		var h = sample_map(x / 50.0, y / 50.0, interpolate)
		h += 0.8
		h /= 1.8
		h *= 300.0
		
#		if(h > water_level):
#			h *= 1000.0
#		else:
#			h *= 100.0
			
		if(h < 0.0):
			terrain_type = TerrainType.ocean
		elif(h < 10.0):
			terrain_type = TerrainType.swamp
		elif(h < 400.0):
			terrain_type = TerrainType.plains
		elif(h < 600.0):
			terrain_type = TerrainType.hill
		elif(h < 800.0):
			terrain_type = TerrainType.mountain
		else:
			terrain_type = TerrainType.snow
		
		if(get_terrain_type):
			return terrain_type
		else:
			return h * vertical_scale
	
	# Generate complex fractal terrain using heightmap image as base
	terrain_type = TerrainType.plains
	var h = 0.0
	var huge = sample_map(x / 320.0 + GameSettings.rand_offset_1, y / 320.0 + GameSettings.rand_offset_2, true)
	huge += 0.25
	
	# Bumps
	h = sample_map(x, y, false) # * 5.0
	
	inland_percent = clamp((huge * 2.5) - 0.2, 0.0, 1.0)
	h += huge * 600
	
	# ocean
	if(h < 0.0):
		terrain_type = TerrainType.ocean
		if(get_terrain_type):
			return terrain_type
		else:
			return h * vertical_scale
	h += (huge * huge) * 500 + inland_percent*10.0
	
	
	# Mountains
	huge += 1.0
	huge /= 2.0
	huge *= huge * huge * huge * huge
	if(huge > 0.2):
		var t = sample_map(y / 27.0 + GameSettings.rand_offset_2, x / 27.0 + GameSettings.rand_offset_3, interpolate)
		t = (t + 1.0) / 2.0
		t *= t * t
		if(t > 0.1):
			h += (huge - 0.2) * 2000 * (t - 0.1)
			terrain_type = TerrainType.mountain
		
		
		
	# Hills
	if(inland_percent > 0.0): # && terrain_type == TerrainType.plains):
		var large = sample_map(x / 10.0 + GameSettings.rand_offset_3, y / 10.0 + GameSettings.rand_offset_1, interpolate) + 0.2
		large *= inland_percent
		
		if(large > 0.1):
			h += (large - 0.1) * 50.0
#			h += 0.5
			terrain_type = TerrainType.hill
		else:
			h += (large - 0.1) * 5.0
			
		if(large < -0.1):
			h += (large + 0.1) * 20.0
#			h -= 0.5
			terrain_type = TerrainType.swamp
	
	
	if(h <= water_level + 1.0):
		terrain_type = TerrainType.lake
	if(h >= snow_level):
		terrain_type = TerrainType.snow
	
	if(get_terrain_type):
		return terrain_type
	else:
		return h * vertical_scale
