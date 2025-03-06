extends AnimatedSprite2D

@onready var player = get_parent()

func _process(delta):
	var factor:float = player.state.run_speed / player.SPEED
	speed_scale = factor
	if (factor < 1.25): pause()
	elif !is_playing(): play()
	
	scale.x = 1
	
	var n:Vector2 = player.state.last_normal
	n = Vector2(-n.y, n.x)
	transform = transform.looking_at(n)
	
	var d = -signf(player.state.v1.x)
	if d != 0.0:
		scale.x = d
