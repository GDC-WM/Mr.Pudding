extends Object
class_name PuddingState

var desired_direction:PackedFloat64Array = [0.0, 0.0]

var last_desired_direction:PackedFloat64Array = [0.0, 0.0]
var direction_changed:Array[bool] = [false, false]
var grounded := false

var jump_height := INF
var jump_hang := INF

var cur_cayote := 0.0

var current_vel:PackedFloat64Array = [0.0, 0.0]

var current_horizontal := Vector2.RIGHT
var current_vertical := Vector2.UP

func update(delta):
	direction_changed[0] = last_desired_direction[0] != desired_direction[0]
	direction_changed[1] = last_desired_direction[1] != desired_direction[1]
	last_desired_direction = desired_direction

func get_velocity() -> Vector2:
	return current_vel[0] * current_horizontal + current_vel[1] * current_vertical

func accelerate(along:int, min:float, max:float, deaccel:float, accel:float, delta:float):
	current_vel[along] = accelerate_component(
		current_vel[along], 
		desired_direction[along], 
		min, max, deaccel, accel, delta
	)

func accelerate_component(from:float, axis:float, min:float, max:float, deaccel:float, accel:float, delta:float) -> float:
	var d := signf(axis)
	var a := accel if d == 1.0 else deaccel
	
	if (d == 0.0): d = -signf(from) #accelerate towards zero if the axis is nuetral
	
	from += d * delta * a
	from = clampf(from, min, max)
	
	if (absf(from) < 10): from = 0.0 #set to zero if close to zero
	
	return from

func hold_on_ground():
	desired_direction[1] = 0
	current_vel[1] = 0.0
	jump_height = 0.0
	jump_hang = 0.0

func start_jump_on_ground(speed:float):
	current_vel[1] = speed
	desired_direction[1] = 1
	grounded = false
	cur_cayote = INF

func hold_jump_in_air(speed:float):
	current_vel[1] = speed
	desired_direction[1] = 1

func hang_in_air(delta:float):
	jump_height = INF
	jump_hang += delta
	desired_direction[1] = 0



func end_jump_in_air():
	jump_height = INF
	jump_hang = INF

func update_jump_height(delta:float):
	if (current_vel[1] > 0): jump_height += current_vel[1] * delta
