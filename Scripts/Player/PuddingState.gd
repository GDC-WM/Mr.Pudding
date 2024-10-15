extends Object
class_name PuddingState

enum MOVEMENT_TYPE {
	WALK,
	DASH,
	RUN
}
var movement_type := MOVEMENT_TYPE.WALK

#the current movement axes of the player
#	change the value of one of these axes to change which way the player will move 
#	add an axis to give the player a new way to move
#
#0: horizontal
#1: vertical
#
#current_vel, desired_direction, last_desired_direction, and direction_changed all use the same indexing scheme
var current_axis_vectors:PackedVector2Array = [Vector2.RIGHT, Vector2.UP]

#the current velocity of the player along each axis in current_axis_vectors
var current_vel:PackedFloat64Array = [0.0, 0.0]

#the direction the player wants to move along each axis in current_axis_vectors
var desired_direction:PackedFloat64Array = [0.0, 0.0]
#the desired directions on the last frame
var last_desired_direction:PackedFloat64Array = [0.0, 0.0]
#whether or not the signs of last_desired_direction are different from desired_direction
var direction_changed:Array[bool] = [false, false]

#whether or not the player is on the ground
var grounded := false

#the height and hang time of the player's current jump, used to calculate if the player should continue rising or fall
var jump_height := INF
var jump_hang := INF

#the current dash time used by the player
var dash_time := 0.0

#the current cayote time used by the player
var cur_cayote := 0.0

#intended to be called every frame to keep last_desired_direction and direction_changed updated
func update(delta):
	for i in desired_direction.size():
		direction_changed[i] = last_desired_direction[i] != desired_direction[i]
		#preserve last direction when desired direction is 0 so that get_facing is preserved
		last_desired_direction[i] = desired_direction[i] if desired_direction[i] != 0 else last_desired_direction[i]

#the "facing" of the character along an axis is either their current direction, or their last direction if no direction is being inputted
func get_facing(axis:int):
	var f := desired_direction[axis] if desired_direction[axis] != 0 else last_desired_direction[axis]
	return f if f != 0 else 1

#the current velocity accumulated from the current velocity along each movement axis
func get_velocity() -> Vector2:
	var vel := Vector2.ZERO
	for i in current_vel.size():
		vel += current_axis_vectors[i] * current_vel[i]
	return vel

#accelerate the player along one of their movement axes
func accelerate(along:int, min:float, max:float, deaccel:float, accel:float, delta:float):
	current_vel[along] = accelerate_component(
		current_vel[along], 
		desired_direction[along], 
		min, max, deaccel, accel, delta
	)

#internal acceleration function
#pure function, works for any float and does not effect the movement axes on its own
func accelerate_component(from:float, axis:float, min:float, max:float, deaccel:float, accel:float, delta:float) -> float:
	var d := signf(axis)
	var a := accel if d == signf(from) else deaccel
	
	if (d == 0.0): d = -signf(from) #accelerate towards zero if the axis is nuetral
	
	from += d * delta * a
	from = clampf(from, min, max)
	
	if (absf(from) < a * 0.005): from = 0.0 #set to zero if close to zero relative to the acceleration
	
	return from

#keep the player on the ground as they walk and reset their jump
func hold_on_ground():
	desired_direction[1] = 0
	current_vel[1] = 0.0
	jump_height = 0.0
	jump_hang = 0.0

#jump off the ground
func start_jump_on_ground(speed:float):
	current_vel[1] = speed
	desired_direction[1] = 1
	grounded = false
	cur_cayote = INF

#hold jump on the rising edge of a jump
func hold_jump_in_air(speed:float):
	current_vel[1] = speed
	desired_direction[1] = 1

#hang in the air at the peak of a jump
func hang_in_air(delta:float):
	jump_height = INF
	jump_hang += delta
	current_vel[1] *= 0.75
	desired_direction[1] = 0

#fall down from the end of a jump
func fall_in_air():
	jump_height = INF
	jump_hang = INF

#increment the jump height, intended to call while the player is rising in a jump
func update_jump_height(delta:float):
	if (current_vel[1] > 0): jump_height += current_vel[1] * delta

#get the desired direction along a movement axis
#useful for comparing desired movement to other vectors in the world
func get_axis_desired(i:int) -> Vector2:
	return current_axis_vectors[i] * desired_direction[i]

#get the current velocity along a movement axis
#used by get_velocity to accumulate a current velocity from each axis
func get_axis_vel(i:int) -> Vector2:
	return current_axis_vectors[i] * current_vel[i]
