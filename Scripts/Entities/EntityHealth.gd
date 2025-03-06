extends ProgressBar
class_name EntityHealth

#Record an entity's health, and kill them if it reaches the minimum value.
#By extending ProgressBar, EntityHealth has all the properties it needs to function right out of the box

@export_node_path("Node2D") var entity_path := NodePath("../")
var entity:Node2D

func _ready():
	reconnect()
	#every time value = ... is called, this signal is fired
	#Godot is a mystery sometimes
	connect("value_changed", check_health)

#Regenerate a reference to the entity and reset health to max
func reconnect():
	entity = get_node(entity_path)
	value = max_value

#check if the entity should die
func check_health(amount:int):
	if (amount <= min_value):
		entity.queue_free()

#change the health value by an amount
func add_health(amount:int):
	value += amount
