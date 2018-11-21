extends Camera

export (NodePath) var target

# Called when the node enters the scene tree for the first time.
func _ready():
	target = get_node(target)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	transform.origin.x = target.transform.origin.x
	transform.origin.z = target.transform.origin.z
	
