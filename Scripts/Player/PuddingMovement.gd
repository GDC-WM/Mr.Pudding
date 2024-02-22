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

var desired_direction := Vector2.ZERO

var last_desired_direction := Vector2.ZERO
var direction_changed:Array[bool] = [false, false]
var grounded := false

var jump_height := INF
var jump_hang := INF

var cur_cayote := 0.0

var current_vel := Vector2.ZERO

func _process(delta):
	update_desired_direction(delta)
	
	#horizontal accelleration
	if grounded:
		current_vel = accelerate(current_vel, 0, -SPEED, SPEED, GROUND_ACCEL, GROUND_ACCEL * DECELLERATION_SCALE, delta)
		current_vel.y = 0.0
	else:
		current_vel = accelerate(current_vel, 0, -SPEED, SPEED, AIR_ACCEL, AIR_ACCEL, delta)
		#vertical acceleration
		current_vel = accelerate(current_vel, 1, -JUMP_SPEED, FALL_SPEED, FALL_ACCEL, FALL_ACCEL, delta)
	
	direction_changed[0] = last_desired_direction[0] != desired_direction[0]
	direction_changed[1] = last_desired_direction[1] != desired_direction[1]
	last_desired_direction = desired_direction

#update the physics body by telling it to move along "current_vel" using built-in functions
func _physics_process(delta):
	velocity = current_vel
	move_and_slide()

func update_desired_direction(delta):
	
	#get input from the player
	var left := Input.is_action_pressed("ui_left")
	var right := Input.is_action_pressed("ui_right")
	var jump := Input.is_action_pressed("ui_accept")
	
	#say that we want some horizontal movement
	desired_direction.x = (-1 if left else 0) + (1 if right else 0)
	
	grounded = is_on_floor()
	if grounded: cur_cayote = 0.0
	
	#if they are, check for jumps
	if grounded || cur_cayote < CAYOTE_TIME:
		desired_direction.y = 0
		jump_height = 0.0
		jump_hang = 0.0
		#if jumping, instantly hit jumping speed
		if jump:
			jump()
	#if in the air, count towards the jump height and jump hang to see if the player should fall
	else:
		if !jump:
			jump_height = INF
			jump_height = INF
		
		if jump_height < JUMP_HEIGHT && jump:
			jump_height -= current_vel.y * delta
			current_vel.y = -JUMP_SPEED
			desired_direction.y = -1
		elif jump_height >= JUMP_HEIGHT && jump_hang < JUMP_HANG && jump:
			jump_height = INF
			jump_hang += delta
			desired_direction.y = 0
		else:
			jump_hang = INF
			desired_direction.y = 1
		
	cur_cayote += delta

#apply acceleration to a vector
#"i" can be an integer or a string,
#vectors in Godot can be indexed with square brackets, v[0] is the same as v['x'] and v.x
func accelerate(v:Vector2, i, min:float, max:float, accel:float, deaccel:float, delta:float):
	var target_v := desired_direction[i] * max
	var d := target_v - v[i]
	var a := signf(d)
	if signf(target_v) != signf(v[i]):
		a *= deaccel
	else:
		a *= accel
	
	v[i] += a * delta
	#zero out v[i] to stop it from jittering around zero
	if desired_direction[i] == 0.0 && absf(v[i]) < absf(a * delta):
		v[i] = 0
	return v

func jump():
	current_vel.y = -JUMP_SPEED
	desired_direction.y = -1
	grounded = false
	cur_cayote = INF
