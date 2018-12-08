extends TextureRect

export (NodePath) var world
export (NodePath) var viewpoint
export (Color) var water_color
export (Color) var sand_color
export (Color) var grass_color
export (Color) var mountain_color
export (Color) var snow_color
export var zoom = 30.0
var noise = preload("res://Scripts/HeightGenerator.gd").new()
var thread = Thread.new()
var reso
var img = Image.new()

var original_pos

var gen_pos = Vector3(0,0,0)
var last_gen_pos = Vector3(0,0,0)

func _ready():
	if(is_visible_in_tree()):
		world = get_node(world)
		viewpoint = get_node(viewpoint)
		noise.init()
		reso = rect_size
		original_pos = rect_position
		img.create(reso.x, reso.y, false, Image.FORMAT_RGBA8)
		start_generating()

func _process(delta):
	if(Input.is_action_just_pressed("ui_focus_next")):
		get_parent().visible = !get_parent().visible
	
	var scroll = last_gen_pos - viewpoint.get_global_transform().origin
	scroll /= zoom
	rect_position = original_pos + Vector2(scroll.x, scroll.z)


func start_generating():
	print("Start generating minimap")
	gen_pos = viewpoint.get_global_transform().origin
	thread.start(self, "generate", gen_pos)

func generate(pos):
	
	# Generate pixels
	img.lock()
	var x = 0
	while(x < reso.x):
		var y = 0
		while(y < reso.y):
			
			var p = Vector3(0,0,0) #pos
			p.x += x - reso.x/2.0
			p.z += y - reso.y/2.0
			p *= zoom
			p += pos
			
			var h = noise.get_h(p)
			var c = Color(0,0,0,0)
			
#			if(h <= 0.0):
#				c = water_color
#			elif(h < 16.0):
#				c = sand_color
#			elif(h < 100.0):
#				c = grass_color
#			elif(h < 256.0):
#				c = mountain_color
#			else:
#				c = snow_color
			
			c = water_color
			if(h > -8.0):
				c = c.linear_interpolate(sand_color, clamp((h + 8.0) / 16.0, 0.0, 1.0))
			if(h > 16.0):
				c = c.linear_interpolate(grass_color, clamp((h - 16.0) / 16.0, 0.0, 1.0))
			if(h > 64.0):
				c = c.linear_interpolate(mountain_color, clamp((h - 64.0) / 64.0, 0.0, 1.0))
			if(h > 220.0):
				c = c.linear_interpolate(snow_color, clamp((h - 220.0) / 64.0, 0.0, 1.0))
			
#			h += 200.0
			h = clamp(h / 300.0, 0.0, 1.0)
			var hc = Color(h, h, h, c.a)
			c = c.linear_interpolate(hc, 0.5)
			
			img.set_pixel(x, y, c)
			y += 1
		x += 1
#	img.flip_x()
#	img.flip_y()
	img.unlock()
	
	# Create texture and finish
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	call_deferred("finish_generating")
	return tex

func finish_generating():
	var tex = thread.wait_to_finish()
	texture = tex
	last_gen_pos = gen_pos
	print("Minimap generated")
	call_deferred("start_generating")
