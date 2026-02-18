class_name WallTrapStrategy
extends MovementStrategy

var side := 1 # 1 for right, -1 for left
var target_x := 201.0
var move_speed := 180.0

func _init(start_side: int = 1):
	side = start_side

func update(meteor: Node2D, delta: float):
	# Consistent downward movement
	meteor.position.y += 160.0 * delta
	
	# Smoothly move towards center X
	var dist_to_target = target_x - meteor.position.x
	if (side == 1 and dist_to_target < 0) or (side == -1 and dist_to_target > 0):
		meteor.position.x += dist_to_target * (1.0 - exp(-3.0 * delta))
