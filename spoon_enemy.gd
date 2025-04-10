extends CharacterBody2D

var facing_direction = 1

var gravity:float = 500.0
var max_fall_speed:float = 200.0
var walk_speed:float = 100.0

func _physics_process(delta):
	if is_on_floor():
		velocity.x = walk_speed * facing_direction
	else:
		velocity.x = lerp(velocity.x, 0.0, 0.01)
		velocity.y = min(velocity.y + gravity * delta, max_fall_speed)
	
	move_and_slide()
	
	# Check wall collision after movement is calculated
	if is_on_wall():
		facing_direction = -facing_direction
	
