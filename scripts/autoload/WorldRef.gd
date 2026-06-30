# QuackCraft - World reference (autoload)
# Holds a reference to the active World node so other systems can find it.
extends Node

var world: Node = null
var player: Node = null

func set_world(w: Node) -> void:
	world = w

func set_player(p: Node) -> void:
	player = p

func get_world() -> Node:
	return world

func get_player() -> Node:
	return player
