extends Object
class_name PuddingState

enum MOVEMENT_TYPE {
	WALK,
	RUN,
	BOUNCE
}

#v1 is "instant" velocity and v2 is "physics" velocity
#on any given physics tick, the player should move the sum of these two
var v1 := Vector2.ZERO
var v2 := Vector2.ZERO
func get_velocity() -> Vector2:
	return v1 + v2

#the direction the player is facing, vertical direction currently means very little
var facing := Vector2.ONE
var movement_axis := Vector2.ZERO
#the value of movement_axis before the last call of update_movement_axis
var last_movement_axis := Vector2.ZERO

var turning:Array[bool] = [false, false]

func update_movement_axis(to:Vector2, can_turn:=true):
	var new_facing = to.sign()
	turning = [new_facing.x != facing.x, new_facing.y != facing.y]
	if (!can_turn && (turning[0] || turning[1])):
		return
	if (to.x != 0.0):facing.x = new_facing.x
	if (to.y != 0.0):facing.y = new_facing.y
	
	last_movement_axis = movement_axis
	movement_axis = to

var movement_type := MOVEMENT_TYPE.WALK

var grounded := false

#the normal the last time the player was grounded
var last_normal := Vector2.UP

var jump_height := 0.0
var jump_rising := false
var coyote_time := 0.0

var run_speed := 0.0

var accepting_input := true

func last_tangent() -> Vector2:
	return Vector2(-last_normal.y, last_normal.x)

enum CLIMB_RESULT {
	OK = 0,
	MAX_RAMP_EXCEEDED,
	MAX_FLOOR_EXCEEDED
}

func try_climb_on(normal:Vector2, max_floor_y:float, max_ramp:=INF) -> CLIMB_RESULT:
	if (normal.y <= max_floor_y):
		var result := !grounded || ((last_normal - normal).length() <= max_ramp)
		#print(!grounded, ", ", ((last_normal - normal).length() <= max_ramp))
		if result: 
			grounded = true
			last_normal = normal
			return CLIMB_RESULT.OK
		return CLIMB_RESULT.MAX_RAMP_EXCEEDED
	else:
		grounded = false
		return CLIMB_RESULT.MAX_FLOOR_EXCEEDED

#try to land the player, assuming they are not grounded
func try_ground(self_collision:KinematicCollision2D, max_floor_y:float, max_ramp:=INF):
	#the player is in the air, only use their direct collisions
	var c_norm = self_collision.get_normal() if self_collision else null
	if c_norm:
		try_climb_on(c_norm, max_floor_y, max_ramp)
	else: grounded = false

#attempt to keep the player on the ground while they are in motion
#supply collision data with the nearest point on the ground, the highest possible floor normal, and "stick_power," the speed with which the player attaches to the ground
func try_cast_down(cast_down_collision:Dictionary, max_floor_y:float, stick_power:float):
	var normal:Vector2 = cast_down_collision["normal"] if cast_down_collision.has("normal") else null
	
	if normal && normal.y <= max_floor_y:
		last_normal = normal
		#pull the player towards the ground
		v2 = -normal * stick_power
	#if they are not standing over anything, launch them back into the air
	else:
		grounded = false

#draw different types of state variables with nice BBCode
func draw_flag(x:bool) -> String:
	return "[color=" + ("green" if x else "red") + "]" + str(x) + "[/color]"

func draw_float(x:float) -> String:
	var color := "yellow"
	var d := signf(x)
	if (d == 1):
		color = "green"
	elif (d == -1):
		color = "red"
	return "[color=" + color + "]" + str(x) + "[/color]"

func draw_m_type(m:MOVEMENT_TYPE) -> String:
	match m:
		MOVEMENT_TYPE.WALK: return "[color=cyan]WALK[/color]"
		MOVEMENT_TYPE.RUN: return "[color=orange]RUN[/color]"
		MOVEMENT_TYPE.BOUNCE: return "[color=pink]BOUNCE[/color]"
	return ""
	

func _to_string():
	return "CATEGORICAL:\n" + \
		"\t" + "grounded: " + draw_flag(grounded) + "\n" + \
		"\t" + "movement mode: " + draw_m_type(movement_type) + "\n" + \
	"PHYSICAL:\n" + \
		"\t instant velocity: (" + draw_float(v1.x) + ", " + draw_float(v1.y) + ")\n" + \
		"\t physics velocity: (" + draw_float(v2.x) + ", " + draw_float(v2.y) + ")\n" + \
		"\t last normal: (" + draw_float(last_normal.x) + ", " + draw_float(last_normal.y) + ")\n" + \
		"\t last tangent: (" + draw_float(last_tangent().x) + ", " + draw_float(last_tangent().y) + ")\n" + \
	"INPUT BASED:\n" + \
		"\t movement axis: (" + draw_float(movement_axis.x) + ", " + draw_float(movement_axis.y) + ")\n" + \
		"\t facing: (" + draw_float(facing.x) + ", " + draw_float(facing.y) + ")\n" + \
		"\t accepting input: " + draw_float(accepting_input) + "\n"
