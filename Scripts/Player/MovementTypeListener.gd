extends Node

@export_node_path("CharacterBody2D") var player_path := NodePath("../")
@onready var player := get_node_or_null(player_path)

var last_mode

func _ready():
	last_mode = player.state.movement_type

func _process(delta):
	if (player.state.movement_type != last_mode):
		var children := get_children()
		for i in get_children().size():
			if i == player.state.movement_type:
				children[i].visible = true
			else:
				children[i].visible = false
	last_mode = player.state.movement_type
