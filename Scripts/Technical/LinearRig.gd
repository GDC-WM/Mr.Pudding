extends Object
class_name LinearRig

var prop
var speed

func _init(p, s):
	prop = p
	speed = s

func update(target, delta:float):
	prop += (target - prop) * speed * delta
	return prop
