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
	
	state.current_vel.x = accelerate(
		state.current_vel.x, 
		state.desired_direction.x, 
		-SPEED, SPEED, 
		GROUND_ACCEL, GROUND_ACCEL * DECELLERATION_SCALE, 
		delta
	)
	state.current_vel.y = accelerate(
		state.current_vel.y, 
		state.desired_direction.y, 
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
	state.desired_direction.x = (-1 if left else 0) + (1 if right else 0)
	
	if (is_on_wall() && get_wall_normal().dot(state.current_horizontal * state.desired_direction.x) < 0.0):
		state.desired_direction.x = 0.0
	
	state.grounded = is_on_floor()
	if state.grounded: state.cur_cayote = 0.0
	
	#if they are, check for jumps
	if state.grounded || state.cur_cayote < CAYOTE_TIME:
		state.desired_direction.y = 0
		state.current_vel.y = 0.0
		state.jump_height = 0.0
		state.jump_hang = 0.0
		#if jumping, instantly hit jumping speed
		if jump:
			state.current_vel.y = JUMP_SPEED
			state.desired_direction.y = 1
			state.grounded = false
			state.cur_cayote = INF
			print("jump")
	#if in the air, count towards the jump height and jump hang to see if the player should fall
	else:
		if !jump:
			state.jump_height = INF
			state.jump_height = INF
		
		if state.jump_height < JUMP_HEIGHT && jump:
			state.current_vel.y = JUMP_SPEED
			state.desired_direction.y = 1
			print("rise")
		elif state.jump_height >= JUMP_HEIGHT && state.jump_hang < JUMP_HANG && jump:
			state.jump_height = INF
			state.jump_hang += delta
			state.desired_direction.y = 0
			print("hang")
		else:
			state.jump_hang = INF
			state.jump_height = INF
			state.desired_direction.y = -1
			print("fall")
		
		if (state.current_vel.y > 0): state.jump_height += state.current_vel.y * delta
		
	state.cur_cayote += delta

func update_axes():
	if state.grounded:
		var n := get_floor_normal()
		state.current_horizontal = Vector2(-n.y, n.x)

func accelerate(from:float, axis:float, min:float, max:float, deaccel:float, accel:float, delta:float) -> float:
	var d := signf(axis)
	var a := accel if d == 1.0 else deaccel
	
	if (d == 0.0): d = -signf(from) #accelerate towards zero if the axis is nuetral
	
	from += d * delta * a
	from = clampf(from, min, max)
	
	if (absf(from) < 10): from = 0.0 #set to zero if close to zero
	
	return from
