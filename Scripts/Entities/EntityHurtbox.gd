extends PhysicsBody2D
class_name EntityHurtbox

#Recieve damage from EntityAttacker hitboxes.

#attaches to an EntityHealth, so it doesn't actually need to reference an entity
@export_node_path("EntityHealth") var entity_health_path := NodePath("../EntityHealth")
var entity_health:EntityHealth

func _ready():
	reconnect()

func reconnect():
	entity_health = get_node(entity_health_path)

func deal_damage(amount:int):
	if (is_instance_valid(entity_health)):
		entity_health.add_health(-amount)
