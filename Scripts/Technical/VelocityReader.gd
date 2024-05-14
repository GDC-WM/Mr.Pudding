extends Object
class_name VelocityReader

var target:Node2D

var last_position:Vector2
var last_velocity:Vector2

var velocity:Vector2
var acceleration:Vector2

func _init(t:Node2D):
	target = t
	last_position = target.position

func update(delta:float) -> void:
	velocity = (target.position - last_position) / delta
	acceleration = (velocity - last_velocity) / delta
	
	last_position = target.position
	last_velocity = velocity

