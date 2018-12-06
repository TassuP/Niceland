extends TextureRect

export (NodePath) var world
export (NodePath) var viewpoint
var noise = preload("res://Scripts/HeightGenerator.gd").new()
var thread = Thread.new()
var reso = Vector2(256, 256)
var img = Image.new()

func _ready():
	if(is_visible_in_tree()):
		world = get_node(world)
		viewpoint = get_node(viewpoint)
		noise.init(world)
		reso = rect_size
		img.create(reso.x, reso.y, false, Image.FORMAT_RGBA8)
		start_generating()

func start_generating():
	print("Start generating minimap")
	var pos = viewpoint.get_global_transform().origin
	pos.y = 0.0
	thread.start(self, "generate", pos)

func generate(pos):
#	print(noise._noise.seed)
	
	# Generate pixels
	img.lock()
	var x = 0
	while(x < reso.x):
		var y = 0
		while(y < reso.y):
			
			var p = Vector3(0,0,0) #pos
			p.x += x - reso.x/2.0
			p.z += y - reso.y/2.0
			p *= 30.0
			
			p += pos
			
#			p += Vector3(x - reso.x / 2.0, 0.0, y - reso.y / 2.0) * 30.0
			
			
			
			var h = clamp(noise.get_h(p) / 200.0, 0.0, 1.0)
			var c = Color(0,0,0,0)
			
			if(h <= 0.0):
				c = Color(0.0, 0.0, 0.0, 0.2)
			elif(h < 0.5):
				c = Color(0.5, 0.5, 0.5, 0.9)
			elif(h < 0.9):
				c = Color(0.6, 0.6, 0.6, 0.9)
			else:
				c = Color(1.0, 1.0, 1.0, 0.9)
			
			c *= h / 2.0 + 0.5
			
			img.set_pixel(x, y, c)
			y += 1
		x += 1
	img.flip_x()
	img.flip_y()
	img.unlock()
	
	# Create texture and finish
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	call_deferred("finish_generating")
	return tex

func finish_generating():
	var tex = thread.wait_to_finish()
	texture = tex
	
	print("Minimap generated")
	call_deferred("start_generating")
