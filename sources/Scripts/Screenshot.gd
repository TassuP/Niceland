extends Node

export var shortcut_action = "screenshot"
export var file_prefix = ""
export(int, 'Datetime', 'Unix Timestamp') var file_tag
var output_path

var _tag = ""
var _index = 0

func _ready():
	
	if not file_prefix.empty():
		file_prefix += "_"
	
	if(OS.is_debug_build()):
		# This works in editor
		output_path = "res://Screenshots/"
	else:
		# This works in exported game
		output_path = OS.get_executable_path().get_base_dir()
		output_path = str(output_path, "/Screenshots/")
	
	var dir = Directory.new()
	if not dir.dir_exists(output_path):
		print("Create folder for screenshots")
		print(output_path)
		dir.make_dir(output_path)
	
	
	
	set_process_input(true)
	
func _input(event):
	if event.is_action_pressed(shortcut_action):
		make_screenshot()

func make_screenshot():
	get_viewport().set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")		
	var image = get_viewport().get_texture().get_data()
	image.flip_y()

	_update_tags()
	image.save_png("%s%s%s_%s.png" % [output_path, file_prefix, _tag, _index])

func _update_tags():
	var time
	if (file_tag == 1): time = str(OS.get_unix_time())
	else:
		time = OS.get_datetime()
		time = "%s_%02d_%02d_%02d%02d%02d" % [time['year'], time['month'], time['day'], 
											time['hour'], time['minute'], time['second']]
	if (_tag == time): _index += 1
	else:
		_index = 0
	_tag = time	
