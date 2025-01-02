extends CharacterBody2D

#speed at which the player can run in pixels per second
const SPEED := 500.0

const MAX_FLOOR_Y := -0.5

#acceleration due to gravity, pixels per second squared
const FALL_ACCEL := 4000.0
#speed at which the player can fall in pixels per second
const FALL_SPEED := 1400.0

#speed at which the player can ascend in pixels per second
const JUMP_SPEED := 800.0
#height that can be jumped to while holding jump
const JUMP_HEIGHT := 200.0
#hang time in the air in seconds while holding jump
const JUMP_HANG := -INF

#time the player can stand off of a platform before being considered no longer grounded
const COYOTE_TIME := 0.2

const RUN_SPEED := 2000.0
const MAX_FLOOR_Y_RUN := 0.0

const RUN_ACCEL := 500.0
const DROP_ACCEL := 1500.0

const STICK_POWER := 400.0

const BOUNCE_POWER := 1000.0

#the max difference in the length between two normals that the player can climb while running
const MAX_RAMP := 1.0

#the state of the player
var state := PuddingState.new()

@onready var casts:Node2D = get_node("Cast")
@onready var cast_down:ShapeCast2D = get_node("Cast/CastDown")
@onready var cast_forward:ShapeCast2D = get_node("Cast/CastForward")

func _ready():
	state.run_speed = SPEED #when we do eventually start running, start at the walk speed

func accelerate(from:float, to:float, accel:float, delta:float) -> float:
	return from + signf(to - from) * delta * accel

func get_last_highest_normal(cast:ShapeCast2D) -> Dictionary:
	var best := {"normal":Vector2.DOWN}
	for result in cast.collision_result:
		if result["normal"].y < best["normal"].y:
			best = result
	return best

func get_last_closest_point(cast:ShapeCast2D) -> Dictionary:
	var best := {}
	var best_distance := INF
	for result in cast.collision_result:
		var d:float = position.distance_to(result["point"])
		if d < best_distance:
			best = result
			best_distance = d
	return best

func update_jump(jump:bool, delta:float):
	
	if state.grounded:
		state.jump_height = 0.0
	
	#start a jump
	if state.coyote_time < COYOTE_TIME:
		if jump:
			state.coyote_time = INF
			state.v2[1] = -JUMP_SPEED
			state.jump_height += JUMP_SPEED * delta
			state.grounded = false
			state.jump_rising = true
			return
	
	#compute the peak of the natural jump arc using the jump speed and fall acceleration
	var root := JUMP_SPEED / (2 * FALL_ACCEL)
	var peak_offset := (JUMP_SPEED * root) - (FALL_ACCEL * root * root)
	
	#use the natural peak to balance out the max height the player can hold jump to
	if jump && state.jump_rising && state.jump_height <= JUMP_HEIGHT - peak_offset:
		state.v2[1] = -JUMP_SPEED
		state.jump_height += JUMP_SPEED * delta
		return
	
	state.jump_rising = false
	
	#after that point, just let them fall
	if state.v2[1] < 0.0:
		state.jump_height -= state.v2[1] * delta
		return

func _process(delta):
	state.update_movement_axis(Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_down", "ui_up")
	), 
	#boolean flag prevents the facing parameter from updating
	#if the player is grounded and running, don't let them turn around
	(state.movement_type != state.MOVEMENT_TYPE.RUN) || \
	(state.coyote_time > COYOTE_TIME) 
	)

func handle_walk(delta):
	
	#check if the player is touching something they could land on
	state.try_ground(
		get_last_slide_collision(),
		MAX_FLOOR_Y
	)
	
	if state.grounded: 
		state.try_cast_down(get_last_highest_normal(cast_down), MAX_FLOOR_Y, STICK_POWER)
	
	if (state.accepting_input): update_jump(Input.is_action_pressed("ui_accept"), delta)
			
	if state.grounded:
		if state.movement_axis == Vector2.ZERO:
			state.v2 = Vector2.ZERO
		
		#if the player is grounded, walk along the slope
		var t := state.last_tangent()
		state.v1 = t * state.movement_axis[0] * SPEED
		#also allow a sprint to start instantly
		if Input.is_action_pressed("sprint"):
			state.movement_type = state.MOVEMENT_TYPE.RUN
	else:
		#if the player is not grounded, still allow them freedom of horizontal movement
		state.v1 = Vector2(state.movement_axis[0] * SPEED, 0.0)
		
		#accelerate the player towards the ground
		state.v2[0] = 0.0
		state.v2[1] += accelerate(state.v1[1], FALL_SPEED, FALL_ACCEL, delta)
		if state.v2[1] != clampf(state.v2[1], -FALL_SPEED, FALL_SPEED):
			state.v2[1] = FALL_SPEED * signf(state.v2[1])
		
		if Input.is_action_pressed("sprint"):
			state.movement_type = state.MOVEMENT_TYPE.DROP

func handle_run(delta):
	
	#check if the player is grounded like in handle_walk, pulling them towards the ground if necessary
	#however, the bound for being grounded in general is the more lenient one for running, which allows wall running to be sustained
	state.try_ground(get_last_slide_collision(), MAX_FLOOR_Y_RUN, MAX_RAMP)
	state.try_cast_down(get_last_highest_normal(cast_down), MAX_FLOOR_Y, STICK_POWER)

	#double check if the player should be grounded. This is what adds wall-running
	#first, check the terrain in front of them, all we care about is the normal
	var result := get_last_closest_point(cast_forward)
	var normal = result["normal"] if result.has("normal") else null
	
	#if the normal is in-range for wall running (i.e. not a ceiling), attach to it
	#the state automatically computes a normal tangent that's used for movement, so this is all we have to do in theory
	#but, in practice, we need to stick to the wall, too, or else the try_ground call above will fail on subsequent frames
	if normal:
		var result_2 := state.try_climb_on(normal, MAX_FLOOR_Y_RUN, MAX_RAMP)
		if result_2 == state.CLIMB_RESULT.OK:
			state.v2 = -normal * STICK_POWER
		else:
			#if we tried to climb on a wall, but failed to, bounce off
			state.v2 = (-state.facing) * BOUNCE_POWER
			state.movement_type = state.MOVEMENT_TYPE.BOUNCE
			update_jump(true, delta)
			return
	
	#check for a jump
	update_jump(Input.is_action_pressed("ui_accept"), delta)
	
	#print("locking run direction with facing: ", state.facing)
	if (state.movement_axis[0] == 0.0):
		state.movement_axis[0] = state.facing[0]
	
	if state.grounded:
		#if the player is grounded, walk along the slope
		var t := state.last_tangent()
		state.v1 = t * state.facing[0] * state.run_speed
	else:
		#if the player is not grounded, still allow them freedom of horizontal movement
		state.v1 = Vector2(state.facing[0] * state.run_speed, 0.0)
		
		#accelerate the player towards the ground
		state.v2[0] = 0.0
		state.v2[1] += accelerate(state.v1[1], FALL_SPEED, FALL_ACCEL, delta)
		if state.v2[1] != clampf(state.v2[1], -FALL_SPEED, FALL_SPEED):
			state.v2[1] = FALL_SPEED * signf(state.v2[1])
	
	#if the player stops pressing sprint at any time, return to walk mode
	if !Input.is_action_pressed("sprint"):
		state.run_speed = SPEED
		state.movement_type = state.MOVEMENT_TYPE.WALK
	
	#increment the running speed to simulate acceleration over time while running
	state.run_speed += RUN_ACCEL * delta
	state.run_speed = clampf(state.run_speed, 0.0, RUN_SPEED)

func handle_bounce(delta):
	var store_facing := state.facing
	state.movement_axis = -store_facing
	
	#emulate walking, but don't record new inputs (for starting runs, drop dashes, etc.)
	#this will update the player's position based on the movement below, and also detect if they land
	handle_walk(delta)
	
	#once the player lands during a bounce, return to walk mode and restore the player's inputs
	if state.grounded:
		state.movement_type = state.MOVEMENT_TYPE.WALK
		return
	
	#otherwise, restore the player's facing so they continue moving against it on the next step
	state.facing = store_facing
	
	#assert that the player does not leave the bounce state, and that the running speed is reset
	state.run_speed = SPEED
	state.movement_type = state.MOVEMENT_TYPE.BOUNCE

func handle_drop(delta):
	
	state.run_speed += DROP_ACCEL * delta
	state.run_speed = clampf(state.run_speed, SPEED, RUN_SPEED)
	
	handle_walk(delta)
	
	if (state.grounded):
		state.movement_type = state.MOVEMENT_TYPE.RUN
	else:
		state.movement_type = state.MOVEMENT_TYPE.DROP

func _physics_process(delta):
	
	#change behavior based on the movement mode
	match state.movement_type:
		state.MOVEMENT_TYPE.WALK:
			handle_walk(delta)
		state.MOVEMENT_TYPE.RUN:
			handle_run(delta)
		state.MOVEMENT_TYPE.BOUNCE:
			handle_bounce(delta)
		state.MOVEMENT_TYPE.DROP:
			handle_drop(delta)
	
	velocity += state.get_velocity()
	move_and_slide()
	velocity = Vector2.ZERO
	casts.scale.x = state.facing.x
	
	#update coyote time regardless of the movement mode
	if state.grounded:
		state.coyote_time = 0.0
	else:
		state.coyote_time += delta
	
