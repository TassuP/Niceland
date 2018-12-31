extends RigidBody

var t = 0.0
var dir = Vector3(0.0, 1.0, 0.0)

func _ready():
	t = 1.0 + randf() * 3.0

func _process(delta):
	t -= delta
	
	if(t <= 0.0):
		t = 1.0 + randf() * 3.0
		dir.x = randf() - randf()
		dir.y = (randf() - randf()) / 2.0
		dir.z = randf() - randf()
		dir = dir.normalized()
	
	linear_velocity = linear_velocity.linear_interpolate(dir * 10.0, delta)
	
	var pos = transform.origin
	var l = transform.looking_at(pos + dir, Vector3(0.001, 1, 0).normalized())
	var a = Quat(transform.basis)
	var b = Quat(l.basis)
	var c = a.slerp(b, delta)
	transform.basis = Basis(c)
	
	