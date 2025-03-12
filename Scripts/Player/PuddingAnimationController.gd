extends AnimatedSprite2D

@onready var player = get_parent()

func speed_factor() -> float:
	return player.state.run_speed / player.SPEED

func update_run_animation():
	speed_scale = speed_factor()
	if (speed_scale < 1.25): pause()
	elif !is_playing(): play()
	
	update_transform()

func update_drop_animation():
	
	scale.x = pow(speed_factor() + player.state.drop_boost_count, 0.5)
	scale.y = 1 / scale.x
	
	rotation = player.state.get_velocity().angle()
	
	modulate = Color.from_hsv(scale.x, 1.0, 0.5, 1.0)

func update_modulate():
	modulate = Color.WHITE

func update_transform():
	scale.x = 1
	scale.y = 1
	
	var n:Vector2 = player.state.last_normal
	n = Vector2(-n.y, n.x)
	transform = transform.looking_at(n)
	
	var d = -signf(player.state.v1.x)
	if d != 0.0:
		scale.x = d

func update_animation_name():
	update_transform()
	update_modulate()
	
	match player.state.movement_type:
		PuddingState.MOVEMENT_TYPE.RUN:
			animation = "run"
		PuddingState.MOVEMENT_TYPE.DROP:
			animation = "drop"
		PuddingState.MOVEMENT_TYPE.WALK:
			animation = "walk"
		_:
			animation = "default"

func _ready():
	update_animation_name()

var movement_type_record = 0
func _process(delta):
	match player.state.movement_type:
		PuddingState.MOVEMENT_TYPE.RUN:
			update_run_animation()
		PuddingState.MOVEMENT_TYPE.DROP:
			update_drop_animation()
	
	if (player.state.movement_type != movement_type_record):
		update_animation_name()
	
	movement_type_record = player.state.movement_type
