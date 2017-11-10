extends Panel

var geometry_lvl_slider
var effects_lvl_slider

var invert_mouse_checkbox
var fullscreen_checkbox
var shadows_checkbox
var dev_mode_checkbox

var apply_button
var time_slider

var terrain
var atmosph

var new_effects_level
var new_geometry_level
var new_shadow_value

func _ready():
	geometry_lvl_slider = get_node("Geometry Level/Geometry Slider")
	effects_lvl_slider = get_node("Effects Level/Effects Slider")
	
	invert_mouse_checkbox = get_node("Invert mouse CheckBox")
	fullscreen_checkbox = get_node("Fullscreen CheckBox")
	shadows_checkbox = get_node("Shadows CheckBox")
	dev_mode_checkbox = get_node("Dev mode CheckBox")
	
	apply_button = get_node("Apply Button")
	time_slider = get_node("Time of day/Time Slider")
	
	apply_button.set_disabled(true)
	
	terrain = get_node("/root/Main/3D/Terrain/Ground")
	atmosph = get_node("/root/Main/3D")
	
	get_sliders_and_stuff()


func get_sliders_and_stuff():
	new_geometry_level = GameSettings.geometry_level
	new_effects_level = GameSettings.effects_level
	new_shadow_value = GameSettings.shadows_on
	geometry_lvl_slider.set_value(new_geometry_level)
	effects_lvl_slider.set_value(new_effects_level)
	
	invert_mouse_checkbox.set_pressed(GameSettings.invert_mouse)
	fullscreen_checkbox.set_pressed(OS.is_window_fullscreen())
	shadows_checkbox.set_pressed(new_shadow_value)
	dev_mode_checkbox.set_pressed(GameSettings.dev_mode)
	
	time_slider.set_value(GameSettings.time_of_day)
	
func _process(delta):
	
	# Toggle pause and menu visibility
	if(Input.is_action_just_pressed("ui_cancel")):
		get_sliders_and_stuff()
		GameSettings.paused = !GameSettings.paused
	if(GameSettings.paused):
		show()
	else:
		hide()
	
	if(GameSettings.geometry_level != new_geometry_level):
		apply_button.set_disabled(false)
	else:
		apply_button.set_disabled(true)
	
	# Apply effects if level changed
	if(GameSettings.effects_level != new_effects_level):
		GameSettings.effects_level = new_effects_level
		atmosph.setup_post_processing_effects()
	
	# Apply shadows if value changed
	if(GameSettings.shadows_on != new_shadow_value):
		GameSettings.shadows_on = new_shadow_value
		atmosph.setup_post_processing_effects()

func _on_Effects_Slider_value_changed( value ):
	new_effects_level = value
func _on_Geometry_Slider_value_changed( value ):
	new_geometry_level = value
func _on_Shadows_CheckBox_toggled( pressed ):
	new_shadow_value = pressed

func _on_Resume_Button_pressed():
	new_geometry_level = GameSettings.geometry_level
	new_effects_level = GameSettings.effects_level
	geometry_lvl_slider.set_value(new_geometry_level)
	effects_lvl_slider.set_value(new_effects_level)
	GameSettings.paused = false
	
func _on_Apply_Button_pressed():
	
	terrain.cancel = true
	
	if(terrain.use_threading):
		if(terrain.thread.is_active()):
			print("Terrain thread busy")
	#		terrain.thread.wait_to_finish()
	
	# Apply effects that require reloading scenetree
	var need_reload = false
	if(GameSettings.geometry_level != new_geometry_level):
		GameSettings.geometry_level = new_geometry_level
		need_reload = true
	
	# Reload scenetree
	if(need_reload):
		GameSettings.reload_all()
	

func toggle_fullscreen(pressed):
	OS.set_window_fullscreen(pressed)

func _change_time( value ):
	GameSettings.time_of_day = value


func toggle_dev_mode( pressed ):
	GameSettings.dev_mode = pressed
	print("GameSettings.dev_mode = ", GameSettings.dev_mode)

func toggle_invert_mouse( pressed ):
	GameSettings.invert_mouse = pressed
