extends Camera2D

#have a camera that moves to anticipate the target's movement, moving ahead of them
#attach to a camera that is the child of it's target

#pixels the camera will offset from the center per units per second of the target's velocity
#technically, that unit comes out to pixel-seconds per unit. go figure
const OFFSETPERUPS := Vector2(0.1, 0.1)

#maximum pixels per second that the camera will move relative to the parent
const MAXSPEED := Vector2(7.0, 3.0)

var vreader:VelocityReader
var prig:LinearRig

func _ready():
	var parent:Node2D = get_parent()
	vreader = VelocityReader.new(parent)
	prig = LinearRig.new(position, MAXSPEED)

func _physics_process(delta):
	vreader.update(delta)
	
	position = prig.update(OFFSETPERUPS * vreader.velocity, delta)
