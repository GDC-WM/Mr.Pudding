extends ProgressBar
class_name EntityHealth

@export_node_path("Node2D") var entity_path := NodePath("../")
var entity:Node2D

func _ready():
	reconnect()
	connect("value_changed", check_health)

func reconnect():
	entity = get_node(entity_path)
	value = max_value

func check_health(amount:int):
	if (amount <= min_value):
		entity.queue_free()

func add_health(amount:int):
	value += amount
