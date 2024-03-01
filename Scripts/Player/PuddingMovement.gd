extends CharacterBody2D

#speed at which the player can run in pixels per second
const SPEED = 600.0
#acceleration due to movement, pixels per second squared
const GROUND_ACCEL := 6000.0
const AIR_ACCEL := 3000.0

#acceleration due to gravity, pixels per second squared
const FALL_ACCEL := 5000.0
#speed at which the player can fall in pixels per second
const FALL_SPEED := 700.0

#speed at which the player can ascend in pixels per second
const JUMP_SPEED = 800.0
#height that can be jumped to while holding jump
const JUMP_HEIGHT = 100.0
#hang time in the air in seconds while holding jump
const JUMP_HANG = 0.15

const DECELLERATION_SCALE = 2.0

const CAYOTE_TIME := 0.1

var state := PuddingState.new()

func _process(delta):
	update_desired_direction(delta)
	
	update_axes()
	
	#apply horizontal acceleration
	state.accelerate(
		0,
		-SPEED, SPEED, 
		GROUND_ACCEL, GROUND_ACCEL * DECELLERATION_SCALE, 
		delta
	)
	#apply vertical acceleration
	state.accelerate(
		1,
		-FALL_SPEED, JUMP_SPEED, 
		FALL_ACCEL, FALL_ACCEL, 
		delta
	)
	state.update(delta)
	
	print(state.current_vel)

#update the physics body by telling it to move along "current_vel" using built-in functions
func _physics_process(delta):
	velocity = state.get_velocity()
	move_and_slide()

func update_desired_direction(delta):
	
	#get input from the player
	var left := Input.is_action_pressed("ui_left")
	var right := Input.is_action_pressed("ui_right")
	var jump := Input.is_action_pressed("ui_accept")
	
	#say that we want some horizontal movement
	state.desired_direction[0] = (-1 if left else 0) + (1 if right else 0)
	
	if (is_on_wall() && get_wall_normal().dot(state.current_horizontal * state.desired_direction[0]) < 0.0):
		state.desired_direction[0] = 0.0
	
	state.grounded = is_on_floor()
	if state.grounded: state.cur_cayote = 0.0
	
	#if they are, check for jumps
	if state.grounded || state.cur_cayote < CAYOTE_TIME:
		state.hold_on_ground()
		#if jumping, instantly hit jumping speed
		if jump:
			state.start_jump_on_ground(JUMP_SPEED)
			print("jump")
	#if in the air, count towards the jump height and jump hang to see if the player should fall
	else:
		if !jump:
			state.end_jump_in_air()
			
		if state.jump_height < JUMP_HEIGHT:
			state.hold_jump_in_air(JUMP_SPEED)
			print("rise")
		elif state.jump_height >= JUMP_HEIGHT && state.jump_hang < JUMP_HANG:
			state.hang_in_air(delta)
			print("hang")
		else:
			state.end_jump_in_air()
			state.desired_direction[1] = -1
			print("fall")
		
		state.update_jump_height(delta)
		
	state.cur_cayote += delta

func update_axes():
	if state.grounded:
		var n := get_floor_normal()
		state.current_horizontal = Vector2(-n.y, n.x)
