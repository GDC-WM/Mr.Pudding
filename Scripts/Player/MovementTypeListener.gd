extends Node

@export_node_path("CharacterBody2D") var player_path := NodePath("../")
@onready var player := get_node_or_null(player_path)

@onready var text_node:RichTextLabel = get_node("RichTextLabel")

func _process(delta):
	text_node.text = str(player.state)
