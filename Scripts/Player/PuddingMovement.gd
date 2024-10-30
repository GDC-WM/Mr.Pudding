extends CharacterBody2D

#speed at which the player can run in pixels per second
const SPEED := 500.0
#acceleration due to movement, pixels per second squared
const GROUND_ACCEL := 6000.0
const AIR_ACCEL := 3000.0

const MAX_RAMP := 0.395

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

#multiplier for acceleration values when turning around
const DECELLERATION_SCALE := 5.0
const RUN_DECEL_SCALE := 2.0
#multiplier for acceleration values when exceeding SPEED 
const WALK_PULL_SCALE := 0.5

#time the player can stand off of a platform before being considered no longer grounded
const CAYOTE_TIME := 0.1

const RUN_SPEED := 1500.0
const RUN_ACCEL := 1000.0

#the state of the player
var state := PuddingState.new()

@onready var casts := get_node("Cast")
@onready var cast_down := get_node("Cast/CastDown")

func _ready():
	floor_max_angle = asin(MAX_RAMP)

#calls every frame, delta is the frame time 
func _process(delta):
	#apply player input to state based on the movement type
	match state.movement_type:
		state.MOVEMENT_TYPE.WALK: update_walk(delta)
		state.MOVEMENT_TYPE.RUN: update_run(delta)
	
	#update state's internal variables
	state.update(delta)

#update the physics body by telling it to move along "current_vel" using built-in functions
func _physics_process(delta):
	
	velocity = state.get_velocity()
	move_and_slide()
	
	casts.scale.x = signf(state.get_facing(0))

func is_pushing(n:Vector2):
	return absf(n.x) >= MAX_RAMP && state.get_facing(0) != signf(n.x)

#call every frame to update the state's measure of coyote time and apply jump behaviors every frame
#jump argument should be true if the player is inputting a jump
func update_jump(delta, jump:bool):
	
	if get_slide_collision_count() == 0:
		state.grounded = false
	
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
	
	#enable to test out the transform axes feature of the player state!
	#state.transform_axes(Transform2D(delta * 0.1, Vector2.ZERO))
	
	#get input from the player
	var left := Input.is_action_pressed("ui_left")
	var right := Input.is_action_pressed("ui_right")
	var jump := Input.is_action_pressed("ui_accept")
	
	var p:Vector2 = cast_down.get_collision_point()
	var n:Vector2 = cast_down.get_collision_normal()
	if cast_down.is_colliding() && state.grounded:
		if (signf(n.y) < 0.0 && absf(n.x) < MAX_RAMP):
			state.current_axis_vectors[0] = Vector2(-n.y, n.x)
			state.grounded = true
		else:
			state.current_axis_vectors[0] = Vector2.RIGHT
			state.grounded = false
	else:
		state.grounded = is_on_floor()
		state.current_axis_vectors[0] = Vector2.RIGHT
	
	update_jump(delta, jump)
	
	#check if the player is running into a wall by checking if they are checking a wall and walking into it
	if (is_pushing(n)):
		state.desired_direction[0] = 0.0
	else:
		if Input.is_action_pressed("sprint") and state.grounded: 
			state.movement_type = state.MOVEMENT_TYPE.RUN
			pass
		state.desired_direction[0] = (-1 if left else 0) + (1 if right else 0)
	
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

#after a dash the player is sprinting
func update_run(delta):
	
	var wall := get_wall_normal()
	
	update_jump(delta, Input.is_action_pressed("ui_accept"))
	
	if state.grounded:
		#if we hit a wall on the ground or stop holding sprint on the ground, stop running
		if (abs(state.current_vel[0]) < SPEED and\
				!Input.is_action_pressed("sprint")
			):
			state.movement_type = state.MOVEMENT_TYPE.WALK
			return
	
	var left := Input.is_action_pressed("ui_left")
	var right := Input.is_action_pressed("ui_right")
	var jump := Input.is_action_pressed("ui_accept")
	
	state.desired_direction[0] = (-1 if left else 0) + (1 if right else 0)
	
	#don't apply horizontal acceleration in the air.
	if state.grounded: state.accelerate(
		0,
		-RUN_SPEED, RUN_SPEED, 
		RUN_ACCEL * RUN_DECEL_SCALE, RUN_ACCEL, 
		delta
	)
	#only apply vertical acceleration in the air
	else: state.accelerate(
		1,
		-FALL_SPEED, JUMP_SPEED, 
		FALL_ACCEL, FALL_ACCEL, 
		delta
	)
	
	
