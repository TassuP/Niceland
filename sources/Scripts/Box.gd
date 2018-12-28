extends RigidBody

export var stop_on_collision = true
export var stop_on_sleep = true

func _process(delta):
	if(stop_on_collision):
		var b = get_colliding_bodies()
		if(b.size() > 0):
			set_mode(RigidBody.MODE_STATIC)
			set_process(false)
	elif(stop_on_sleep):
		if(sleeping):
			set_mode(RigidBody.MODE_STATIC)
			set_process(false)
	else:
		set_process(false)