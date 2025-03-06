extends Node2D

@export_node_path("CharacterBody2D") var player_path := NodePath("../")
@onready var player := get_node_or_null(player_path)

@export var i := 0
@export_range(-2 * PI, 2 * PI) var offset := 0.0

func _process(_delta):
	if player:
		rotation = player.state.current_axis_vectors[i].angle() + offset
