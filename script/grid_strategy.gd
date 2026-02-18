class_name GridStrategy
extends MovementStrategy

var cols := 4
var spacing := Vector2(80, 60)
var grid_index := 0

func _init(index: int = 0):
	grid_index = index

func update(meteor: Node2D, delta: float):
	# Vertical movement (shared by fleet or independent)
	var parent = meteor.get_parent()
	if not (parent and "direction" in parent):
		meteor.position.y += 100 * delta
	
	# The horizontal part is usually handled by FleetMovement or the FleetController
	# But if we want it to be part of the strategy:
	var row = grid_index / cols
	var col = grid_index % cols
	
	# We don't force position here to allow FleetController to shift the whole group
