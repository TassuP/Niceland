extends TextureRect

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

var original_pos

var gen_pos = Vector3(0,0,0)
var last_gen_pos = Vector3(0,0,0)

var allow_generating = true
var quitting = false
var mutex = Mutex.new()

func _ready():
	if(is_visible_in_tree()):
		viewpoint = get_node(viewpoint)
		noise.init()
		reso = rect_size
		original_pos = rect_position
		start_generating()

func _process(delta):
	if(Input.is_action_just_pressed("ui_focus_next")):
		get_parent().visible = !get_parent().visible
	
	var scroll = last_gen_pos - viewpoint.get_global_transform().origin
	scroll /= zoom
	rect_position = original_pos + Vector2(scroll.x, scroll.z)
	
	if(allow_generating):
		if(scroll.length() >= 8.0):
			start_generating()


func start_generating():
#	print("Start generating minimap")
	allow_generating = false
	gen_pos = viewpoint.get_global_transform().origin
	thread.start(self, "generate", gen_pos)

func generate(pos):
	
	var img = Image.new()
	img.create(reso.x, reso.y, false, Image.FORMAT_RGBA8)
	
	# Generate pixels
	img.lock()
	var x = 0
	while(x < reso.x):
		var y = 0
		while(y < reso.y):
			
			var p = Vector3(0,0,0)
			p.x += x - reso.x/2.0
			p.z += y - reso.y/2.0
			p *= zoom
			p += pos
			
			var h = noise.get_h(p)
			var c = Color(0,0,0,0)
			
			c = water_color
			if(h > -8.0):
				c = c.linear_interpolate(sand_color, clamp((h + 8.0) / 16.0, 0.0, 1.0))
			if(h > 8.0):
				c = c.linear_interpolate(grass_color, clamp((h - 8.0) / 16.0, 0.0, 1.0))
			if(h > 64.0):
				c = c.linear_interpolate(mountain_color, clamp((h - 64.0) / 64.0, 0.0, 1.0))
			if(h > 220.0):
				c = c.linear_interpolate(snow_color, clamp((h - 220.0) / 500.0, 0.0, 1.0))
			
#			h += 200.0
			h = clamp(h / 300.0, 0.0, 1.0)
			var hc = Color(h, h, h, c.a)
			c = c.linear_interpolate(hc, 0.5)
			
			img.set_pixel(x, y, c)
			
			# Not sure if I'm doing this right
			if(mutex.try_lock() == OK):
				if(quitting):
					mutex.unlock()
					img.unlock()
					return # Break this loop
				else:
					mutex.unlock()
			
			y += 1
		x += 1
	img.unlock()
	
	# Create texture and finish
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	call_deferred("finish_generating")
	return tex

func finish_generating():
	if(quitting):
		return
	
	var tex = thread.wait_to_finish()
	
	texture = tex
	last_gen_pos = gen_pos
#	rect_position = original_pos
#	print("Minimap generated")
	
	if(Globals.generate_just_once == false):
		allow_generating = true


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		
		# Not sure if I'm doing this right
		mutex.lock()
		quitting = true # Break loop inside the thread
		mutex.unlock()
		
		if(thread.is_active()):
			thread.wait_to_finish()
		
