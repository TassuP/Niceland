extends Label

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_I:
			visible = !visible