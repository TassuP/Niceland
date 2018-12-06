extends Node

export var shortcut_action = "" setget set_shortcut_action
export var file_prefix = ""
export(int, 'Datetime', 'Unix Timestamp') var file_tag
export(String, DIR) var output_path = "res://" setget set_output_path

var _tag = ""
var _index = 0

func _ready():
	_check_actions([shortcut_action])
	_check_path(output_path)
	
	if not output_path[-1] == "/":
		output_path += "/"
	if not file_prefix.empty():
		file_prefix += "_"
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

func _check_actions(actions=[]):
	if OS.is_debug_build():
		var message = 'WARNING: No action "%s"'
		for action in actions:
			if not InputMap.has_action(action):
				print(message % action)
				#breakpoint
				
func _check_path(path):
	if OS.is_debug_build():
		var message = 'WARNING: No directory "%s"'
		var dir = Directory.new()
		dir.open(path)
		if not dir.dir_exists(path):
			print(message % path)
			#breakpoint
			
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
	
func set_shortcut_action(action):
	_check_actions([action])
	shortcut_action = action
	
func set_output_path(path):
	_check_path(path)
	output_path = path