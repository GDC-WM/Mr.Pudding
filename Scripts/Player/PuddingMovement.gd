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

const STICK_POWER := 400.0

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
	))

func handle_walk(delta):
	
	#check if the player is touching something they could land on
	state.try_ground(
		get_last_slide_collision(),
		MAX_FLOOR_Y
	)
	
	if state.grounded: 
		state.try_cast_down(get_last_highest_normal(cast_down), MAX_FLOOR_Y, STICK_POWER)
	
	update_jump(Input.is_action_pressed("ui_accept"), delta)
			
	if state.grounded:
		if state.movement_axis == Vector2.ZERO:
			state.v2 = Vector2.ZERO
		
		#if the player is grounded, walk along the slope
		var t := state.last_tangent()
		state.v1 = t * state.movement_axis[0] * SPEED
		#also allow a sprint to start instantly
		if state.v1 != Vector2.ZERO && \
			Input.is_action_pressed("sprint"):
			state.movement_type = state.MOVEMENT_TYPE.RUN
	else:
		#if the player is not grounded, still allow them freedom of horizontal movement
		state.v1 = Vector2(state.movement_axis[0] * SPEED, 0.0)
		
		#accelerate the player towards the ground
		state.v2[0] = 0.0
		state.v2[1] += accelerate(state.v1[1], FALL_SPEED, FALL_ACCEL, delta)
		if state.v2[1] != clampf(state.v2[1], -FALL_SPEED, FALL_SPEED):
			state.v2[1] = FALL_SPEED * signf(state.v2[1])

func handle_run(delta):
	
	#no pausing
	if (state.movement_axis[0] == 0.0):
		state.movement_axis[0] = state.facing[0]
		
	if state.grounded: 
		state.try_cast_down(get_last_highest_normal(cast_down), MAX_FLOOR_Y, STICK_POWER)
	
	var result := get_last_closest_point(cast_forward)
	var normal = result["normal"] if result.has("normal") else null
	if normal && normal.y <= MAX_FLOOR_Y_RUN:
		state.last_normal = normal
		state.v2 = -normal * STICK_POWER
		state.grounded = true
	#if we face away from the last wall, which was too steep to walk on, fall
	#this feels better because walls have an easy escape, but floors are still floors
	elif state.last_normal.y > MAX_FLOOR_Y && (state.last_normal * state.movement_axis).x < 0.0:
		state.grounded = false
	
	update_jump(Input.is_action_pressed("ui_accept"), delta)

	if state.grounded:
		#if the player is grounded, walk along the slope
		var t := state.last_tangent()
		state.v1 = t * state.movement_axis[0] * state.run_speed
		
		#allow returning to walk instantaneously
		if state.facing.x != state.movement_axis.x || \
			!Input.is_action_pressed("sprint"):
			
			state.run_speed = SPEED
			state.movement_type = state.MOVEMENT_TYPE.WALK
	else:
		#if the player is not grounded, still allow them freedom of horizontal movement
		state.v1 = Vector2(state.movement_axis[0] * state.run_speed, 0.0)
		
		#accelerate the player towards the ground
		state.v2[0] = 0.0
		state.v2[1] += accelerate(state.v1[1], FALL_SPEED, FALL_ACCEL, delta)
		if state.v2[1] != clampf(state.v2[1], -FALL_SPEED, FALL_SPEED):
			state.v2[1] = FALL_SPEED * signf(state.v2[1])

	state.run_speed += RUN_ACCEL * delta
	state.run_speed = clampf(state.run_speed, 0.0, RUN_SPEED)
	

func _physics_process(delta):
	
	#change behavior based on the movement mode
	match state.movement_type:
		state.MOVEMENT_TYPE.WALK:
			handle_walk(delta)
		state.MOVEMENT_TYPE.RUN:
			handle_run(delta)
	
	velocity += state.get_velocity()
	print(velocity)
	move_and_slide()
	velocity = Vector2.ZERO
	casts.scale.x = state.facing.x
	
	#update coyote time regardless of the movement mode
	if state.grounded:
		state.coyote_time = 0.0
	else:
		state.coyote_time += delta
	
