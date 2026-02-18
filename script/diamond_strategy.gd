class_name DiamondStrategy
extends MovementStrategy

var radius := 120.0
var rotation_speed := 1.5
var angle := 0.0
var time := 0.0

func _init(idx: int = 0):
	angle = idx * (PI / 2.0)

func update(meteor: Node2D, delta: float):
	time += delta
	angle += rotation_speed * delta
	
	# Smoothly oscillating radius for more "diamond" like feel or rounded diamond
	var current_radius = radius * (0.8 + 0.2 * sin(time * 2.0))
	var offset = Vector2(cos(angle), sin(angle)) * current_radius
	
	# Move downward
	meteor.position.y += 120 * delta
	# Apply horizontal oscillation relative to spawn
	if meteor.has_meta("spawn_x"):
		meteor.position.x = meteor.get_meta("spawn_x") + offset.x
	else:
		meteor.position.x += offset.x * delta # Fallback
