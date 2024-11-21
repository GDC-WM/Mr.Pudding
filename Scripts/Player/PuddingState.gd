extends Object
class_name PuddingState

enum MOVEMENT_MODE {
	WALK,
}

var internal_velocity := Vector2(0.0,0.0)

var movement_type := MOVEMENT_MODE.WALK

var grounded := false
var pushing_wall := false

var last_normal = Vector2.UP

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

func _to_string():
	return "FLAGS:\n" + \
		"\t" + "grounded: " + draw_flag(grounded) + "\n" + \
	"VARIABLES:\n" + \
		"\t internal_velocity: (" + draw_float(internal_velocity.x) + ", " + draw_float(internal_velocity.y) + ")\n"
