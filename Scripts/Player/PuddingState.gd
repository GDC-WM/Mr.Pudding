extends Object
class_name PuddingState

var desired_direction := Vector2.ZERO

var last_desired_direction := Vector2.ZERO
var direction_changed:Array[bool] = [false, false]
var grounded := false

var jump_height := INF
var jump_hang := INF

var cur_cayote := 0.0

var current_vel := Vector2.ZERO

func update(delta):
	direction_changed[0] = last_desired_direction[0] != desired_direction[0]
	direction_changed[1] = last_desired_direction[1] != desired_direction[1]
	last_desired_direction = desired_direction
