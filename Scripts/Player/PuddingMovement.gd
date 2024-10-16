extends CharacterBody2D

#speed at which the player can run in pixels per second
const SPEED := 500.0
#acceleration due to movement, pixels per second squared
const GROUND_ACCEL := 6000.0
const AIR_ACCEL := 3000.0

#acceleration due to gravity, pixels per second squared
const FALL_ACCEL := 4000.0
const FASTFALL_ACCEL_MULTIPLIER := 1.5
#speed at which the player can fall in pixels per second
const FALL_SPEED := 1400.0

#speed at which the player can ascend in pixels per second
const JUMP_SPEED := 800.0
#height that can be jumped to while holding jump
const JUMP_HEIGHT := 75.0
#hang time in the air in seconds while holding jump
const JUMP_HANG := -INF

#constant speed of the player's dash in pixels per second
const DASH_SPEED := 750.0
#time the player dashes for before entering the run state
const DASH_TIME := 0.25

#multiplier for acceleration values when turning around
const DECELLERATION_SCALE := 5.0
#multiplier for acceleration values when exceeding SPEED 
const WALK_PULL_SCALE := 0.1

#time the player can stand off of a platform before being considered no longer grounded
const CAYOTE_TIME := 0.1

const RUN_SPEED := 2000.0
const RUN_ACCEL := 800.0

#the state of the player
var state := PuddingState.new()

#calls every frame, delta is the frame time 
func _process(delta):
	#transition state base on player input
	if Input.is_action_pressed("dash") and state.movement_type == state.MOVEMENT_TYPE.WALK:
		state.movement_type = state.MOVEMENT_TYPE.DASH
		state.dash_time = 0.0
	
	if !Input.is_action_pressed("sprint") and state.movement_type == state.MOVEMENT_TYPE.RUN:
		state.movement_type = state.MOVEMENT_TYPE.WALK
	
	#apply player input to state based on the movement type
	match state.movement_type:
		state.MOVEMENT_TYPE.WALK: update_walk(delta)
		state.MOVEMENT_TYPE.DASH: update_dash(delta)
		state.MOVEMENT_TYPE.RUN: update_run(delta)
	
	#update state's internal variables
	state.update(delta)
	
	print(state.current_vel)

#update the physics body by telling it to move along "current_vel" using built-in functions
func _physics_process(delta):
	velocity = state.get_velocity()
	move_and_slide()

func is_pressing_wall():
	return is_on_wall() && get_wall_normal().dot(state.get_axis_vel(0)) < 0.0

#call every frame to update the state's grounded variable
func update_grounded():
	state.grounded = is_on_floor()
	
	if state.grounded:
		var n := get_floor_normal()
		state.current_axis_vectors[0] = Vector2(-n.y, n.x)

#call every frame to update the state's measure of coyote time and apply jump behaviors every frame
#jump argument should be true if the player is inputting a jump
func update_jump(delta, jump:bool):
	update_grounded()
	
	if state.grounded:
		state.cur_cayote = 0.0
		state.hold_on_ground()
	else:
		state.cur_cayote += delta
	#if jumping, instantly hit jumping speed
	if jump && state.cur_cayote < CAYOTE_TIME:
		state.start_jump_on_ground(JUMP_SPEED)
		print("jump")
	
	#if in the air, count towards the jump height and jump hang to see if the player should fall
	elif !state.grounded:
		if !jump:
			#if a jump ended prematurely, cut the player's upward velocity
			if state.jump_height < JUMP_HEIGHT:
				state.current_vel[1] *= 0.5
			state.fall_in_air()
			
		if state.jump_height < JUMP_HEIGHT:
			state.hold_jump_in_air(JUMP_SPEED)
			print("rise")
		elif state.jump_height >= JUMP_HEIGHT && state.jump_hang < JUMP_HANG:
			state.hang_in_air(delta)
			print("hang")
		else:
			state.fall_in_air()
			state.desired_direction[1] = -1
			print("fall")
		
		state.update_jump_height(delta)

#take input from the player and apply it to state.desired_direction
func update_walk(delta):
	
	#get input from the player
	var left := Input.is_action_pressed("ui_left")
	var right := Input.is_action_pressed("ui_right")
	var jump := Input.is_action_pressed("ui_accept")
	
	#check if the player is running into a wall by checking if they are checking a wall and walking into it
	if (is_pressing_wall()):
		state.desired_direction[0] = 0.0
	else:
		state.desired_direction[0] = (-1 if left else 0) + (1 if right else 0)
	
	update_jump(delta, jump)
	
	#apply state's other variables to velocity using acceleration
	#apply horizontal acceleration
	if state.axis_pull(state.current_vel[0], -SPEED, SPEED):
		state.accelerate(
			0,
			-SPEED, SPEED, 
			GROUND_ACCEL * WALK_PULL_SCALE, GROUND_ACCEL * WALK_PULL_SCALE, 
			delta
		)
	else:
		state.accelerate(
			0,
			-SPEED, SPEED, 
			GROUND_ACCEL * DECELLERATION_SCALE, GROUND_ACCEL, 
			delta
		)
	
	#apply vertical acceleration
	var fall_accel_mul = FASTFALL_ACCEL_MULTIPLIER if state.jump_height >= JUMP_HEIGHT else 1
	state.accelerate(
		1,
		-FALL_SPEED, JUMP_SPEED, 
		FALL_ACCEL * fall_accel_mul, FALL_ACCEL * fall_accel_mul, 
		delta
	)

#push the player forwards
func update_dash(delta):
	state.desired_direction[0] = state.get_facing(0)
	state.desired_direction[1] = 0
	
	state.dash_time += delta
	if (state.dash_time >= DASH_TIME || is_pressing_wall()):
		state.movement_type = state.MOVEMENT_TYPE.RUN
		return
	
	state.current_vel[0] = state.get_facing(0) * DASH_SPEED
	state.current_vel[1] = 0.0

#after a dash the player is sprinting
func update_run(delta):
	update_grounded()
	
	#implement wall running later, lol. If I crash into a walk, return to walking mode, which has cases for running into walls
	if (is_pressing_wall()):
		state.movement_type = state.MOVEMENT_TYPE.WALK
		return
	
	var left := Input.is_action_pressed("ui_left")
	var right := Input.is_action_pressed("ui_right")
	var jump := Input.is_action_pressed("ui_accept")
	
	state.desired_direction[0] = (-1 if left else 0) + (1 if right else 0)
	
	#give the player a speed boost if they land within walking speed while sprinting
	if signf(state.desired_direction[0]) == signf(state.current_vel[0]) && state.axis_pull(state.current_vel[0], -SPEED, SPEED) == 0:
		state.current_vel[0] *= RUN_SPEED / SPEED
	
	state.accelerate(
		0,
		-RUN_SPEED, RUN_SPEED, 
		RUN_ACCEL, RUN_ACCEL, 
		delta
	)
	
	
