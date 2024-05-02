extends PhysicsBody2D
class_name EntityHurtbox

@export_node_path("EntityHealth") var entity_health_path := NodePath("../EntityHealth")
var entity_health:EntityHealth

@export_node_path("Node2D") var entity_path := NodePath("../")
var entity:Node2D

func _ready():
	reconnect()

func reconnect():
	entity_health = get_node(entity_health_path)
	entity = get_node(entity_path)

func deal_damage(amount:int):
	if (is_instance_valid(entity_health)):
		entity_health.add_health(-amount)
