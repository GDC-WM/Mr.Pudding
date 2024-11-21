extends CharacterBody2D

#speed at which the player can run in pixels per second
const SPEED := 500.0
#acceleration due to movement, pixels per second squared
const GROUND_ACCEL := 6000.0
const AIR_ACCEL := 3000.0

const MAX_RAMP := 0.395
const MAX_STEP := 610

#acceleration due to gravity, pixels per second squared
const FALL_ACCEL := 4000.0
const FASTFALL_ACCEL_MULTIPLIER := 1.5
#speed at which the player can fall in pixels per second
const FALL_SPEED := 1400.0

#speed at which the player can ascend in pixels per second
const JUMP_SPEED := 800.0
#height that can be jumped to while holding jump
const JUMP_HEIGHT := 75.0
#hang time in the air in seconds while holding jump
const JUMP_HANG := -INF

#multiplier for acceleration values when turning around
const DECELLERATION_SCALE := 5.0
const RUN_DECEL_SCALE := 2.0
#multiplier for acceleration values when exceeding SPEED 
const WALK_PULL_SCALE := 0.5

#time the player can stand off of a platform before being considered no longer grounded
const CAYOTE_TIME := 0.1

const RUN_SPEED := 1500.0
const RUN_ACCEL := 1000.0

#the state of the player
var state := PuddingState.new()

@onready var casts:Node2D = get_node("Cast")
@onready var cast_down:RayCast2D = get_node("Cast/CastDown")
@onready var cast_forward:RayCast2D = get_node("Cast/CastForward")
@onready var cast_latch:RayCast2D = get_node("Cast/CastLatch")

func _process(delta):
	state.internal_velocity[0] = Input.get_axis("ui_left", "ui_right") * SPEED

func _physics_process(delta):
	velocity = state.internal_velocity
	move_and_slide()
