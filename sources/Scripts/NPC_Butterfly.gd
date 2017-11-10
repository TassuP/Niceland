extends Spatial

var speed = 3.0
var t = 0.0

func _ready():
	t = randf() * 6.0

func _process(delta):
	
	if(GameSettings.paused):
		return
	
	t += delta / 10.0
	
	var move = Vector3(1, 0.5, 1)
	
	move.x *= sin(t) * sin(t / 2)
	move.y *= sin(t)
	move.z *= sin(t) * cos(t / 2)
	
	
	
	var tr = get_global_transform()
	var h = Height_Main.gen(tr.origin.x, tr.origin.z, false, true) + 0.2
	
	tr.origin.y += move.y
	
	if(tr.origin.y < h):
		tr.origin.y = h
		set_global_transform(tr)
	else:
		translate(move * delta * speed)
	