extends Node

export var enabled = true
var fade_speed = 0.1
var mute = -32.0
var vol1 = mute
var vol2 = mute
var vol3 = mute
var vol4 = mute

var current_state = 0
var switch_timer = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	if(enabled == false):
		queue_free()
		set_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	switch_timer -= delta
	if(switch_timer <= 0.0):
		switch_timer = 10.0 + randf() * 10.0
		current_state = randi() % 5
		print("Change music state to ", current_state)
	
	
	if(Input.is_key_pressed(KEY_1)):
		current_state = 0
	if(Input.is_key_pressed(KEY_2)):
		current_state = 1
	if(Input.is_key_pressed(KEY_3)):
		current_state = 2
	if(Input.is_key_pressed(KEY_4)):
		current_state = 3
	if(Input.is_key_pressed(KEY_5)):
		current_state = 4
	
	var f = fade_speed * delta
	match(current_state):
		0:
			vol1 = lerp(vol1, mute, f)
			vol2 = lerp(vol2, mute, f)
			vol3 = lerp(vol3, mute, f)
			vol4 = lerp(vol4, 0.0, f)
		1:
			vol1 = lerp(vol1, 0.0, f)
			vol2 = lerp(vol2, 0.0, f)
			vol3 = lerp(vol3, mute, f)
			vol4 = lerp(vol4, mute, f)
		2:
			vol1 = lerp(vol1, 0.0, f)
			vol2 = lerp(vol2, mute, f)
			vol3 = lerp(vol3, mute, f)
			vol4 = lerp(vol4, 0.0, f)
		3:
			vol1 = lerp(vol1, 0.0, f)
			vol2 = lerp(vol2, 0.0, f)
			vol3 = lerp(vol3, mute, f)
			vol4 = lerp(vol4, mute, f)
		4:
			vol1 = lerp(vol1, 0.0, f)
			vol2 = lerp(vol2, 0.0, f)
			vol3 = lerp(vol3, 0.0, f)
			vol4 = lerp(vol4, 0.0, f)
	
	$Drums.volume_db = vol1
	$Bass.volume_db = vol2
	$Cheese.volume_db = vol3
	$Pad.volume_db = vol4
	
