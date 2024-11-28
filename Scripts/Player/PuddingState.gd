extends Object
class_name PuddingState

enum MOVEMENT_TYPE {
	WALK,
	RUN
}

#v1 is "instant" velocity and v2 is "physics" velocity
#on any given physics tick, the player should move the sum of these two
var v1 := Vector2.ZERO
var v2 := Vector2.ZERO
func get_velocity() -> Vector2:
	return v1 + v2

var facing := Vector2.ONE
var movement_axis := Vector2.ZERO

func update_movement_axis(to:Vector2):
	if (to.x != 0.0): facing.x = signf(to.x)
	if (to.y != 0.0): facing.y = signf(to.y)
	movement_axis = to

var movement_type := MOVEMENT_TYPE.WALK

var grounded := false
var pushing_wall := false

var last_normal = Vector2.UP

var jump_height := 0.0
var jump_rising := false
var coyote_time := 0.0

var run_speed := 0.0

func last_tangent() -> Vector2:
	return Vector2(-last_normal.y, last_normal.x)

#try to land the player, assuming they are not grounded
func try_ground(self_collision:KinematicCollision2D, max_floor_y:float):
	#the player is in the air, only use their direct collisions
	var c_norm = self_collision.get_normal() if self_collision else null
	if c_norm && c_norm.y <= max_floor_y:
		grounded = true
		last_normal = c_norm
	else:
		grounded = false

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
	return ""
	

func _to_string():
	return "CATEGORICAL:\n" + \
		"\t" + "grounded: " + draw_flag(grounded) + "\n" + \
		"\t" + "movement mode: " + draw_m_type(movement_type) + "\n" + \
	"CONTINUOUS:\n" + \
		"\t instant velocity: (" + draw_float(v1.x) + ", " + draw_float(v1.y) + ")\n" + \
		"\t physics velocity: (" + draw_float(v2.x) + ", " + draw_float(v2.y) + ")\n" + \
		"\t last normal: (" + draw_float(last_normal.x) + ", " + draw_float(last_normal.y) + ")\n" + \
		"\t last tangent: (" + draw_float(last_tangent().x) + ", " + draw_float(last_tangent().y) + ")\n"
