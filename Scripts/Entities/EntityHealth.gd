extends ProgressBar

@export_node_path("Node2D") var entity_path := NodePath("../")

var entity:Node2D

func _ready():
	reconnect()
	connect("value_changed", check_health)

func reconnect():
	entity = get_node(entity_path)

func check_health():
	if (value <= min_value):
		entity.queue_free()
