extends TextureRect

export (NodePath) var world
var thread = Thread.new()
var reso = Vector2(256, 160)

func _ready():
	if(is_visible_in_tree()):
		world = get_node(world)
#		call_deferred("generate")
		start_generating()

func start_generating():
	print("Start generating minimap")
	thread.start(self, "generate", world.game_seed)

# Functions 'make_noise' and 'get_h' are copied from ground,
# and they must be identical copies.
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

func generate(_seed):
	
	# Create noise and an image
	var noise = make_noise(_seed)
	var img = Image.new()
	img = noise.get_image(reso.x, reso.y)
	
	# Generate pixels
	img.lock()
	var x = 0
	while(x < reso.x):
		var y = 0
		while(y < reso.y):
			var p = Vector3(x, 0.0, y) * 20.0
			var h = clamp(get_h(noise, p) / 200.0, 0.0, 1.0)
			var c = Color(0,0,0,0)
			
			if(h <= 0.0):
				c = Color(0.3, 0.3, 0.3, 0.5)
			elif(h < 0.5):
				c = Color(0.3, 0.3, 0.3, 0.7)
			elif(h < 0.9):
				c = Color(0.6, 0.6, 0.6, 0.7)
			else:
				c = Color(1.0, 1.0, 1.0, 0.7)
			
			c *= h / 2.0 + 0.5
			
			img.set_pixel(x, y, c)
			y += 1
		x += 1
	img.unlock()
	
	# Create texture and finish
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	call_deferred("finish_generating")
#	texture = tex
	return tex

func finish_generating():
	var tex = thread.wait_to_finish()
	texture = tex
	
	print("Minimap generated")
