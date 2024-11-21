extends CharacterBody2D

##Have a camera that moves to anticipate the target's movement, moving ahead of them
##The "camera" also interacts with colliders, for this reason, the script should be attached to a CharacterBody2D
##The CharacterBody2D should have a camera and its own collider as children
##The CharacterBody2D's collision layers shouldn't interact with the base terrain, 
##but should with colliders denoting level borders. 

#pixels the camera will move ahead of its target, showing the player what's ahead of them
const OFFSETPERUPS := Vector2(.1,.1)

#maximum pixels per second that the camera will move relative to the target
const MAXSPEED := Vector2(5.0, 3.0)

#attached to the target to read their velocity
var vreader:VelocityReader

#used to smooth the position according to MAXSPEED and OFFSETPERUPS
var prig:LinearRig

#reference to the target. Usually the player, but works for any Node2D
@export_node_path("Node2D") var player_path = NodePath("../CharacterBody2D")
@onready var player = get_node(player_path)

#the target position the camera approaches
#ideally, the position variable should be set to directly, 
#but for the camera to collide with world boundaries it has to move via the velocity variable
var target_position := position

#set up vreader and prig
func _ready():
	vreader = VelocityReader.new(player)
	prig = LinearRig.new(target_position, MAXSPEED)

func _physics_process(delta):
	#read the target's velocity
	vreader.update(delta)
	
	#smoothly interpolate the current position of the camera to where it wants to go
	target_position = prig.update(player.position + OFFSETPERUPS * vreader.velocity, delta)
	
	#apply the position change as velocity
	#prig already applies delta scaling, so we need to undo the scaling applied by the engine physics
	#this is FANTASTICALLY DANGER-OUS, if the delta scaling of prig changes at all, the camera will go flying, and it will be my fault :)
	velocity = (target_position - position) / delta 
	
	#apply the velocity to the camera so that they are stopped by barriers
	move_and_slide()
