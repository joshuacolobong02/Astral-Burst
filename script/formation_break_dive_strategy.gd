class_name FormationBreakDiveStrategy
extends MovementStrategy

var wait_time := 2.0
var dive_strategy: DiveMovement

func _init(player_pos: Vector2 = Vector2.ZERO, delay: float = 2.0):
	wait_time = delay
	dive_strategy = DiveMovement.new(player_pos)

func update(meteor: Node2D, delta: float):
	if wait_time > 0:
		wait_time -= delta
		# Stay in place or move with fleet
	else:
		dive_strategy.update(meteor, delta)
