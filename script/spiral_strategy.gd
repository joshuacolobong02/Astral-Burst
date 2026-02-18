class_name SpiralStrategy
extends MovementStrategy

var rotation_speed := 3.0
var base_radius := 120.0
var time := 0.0
var index_offset := 0.0

func _init(idx: int = 0):
	index_offset = idx * 0.4

func update(meteor: Node2D, delta: float):
	time += delta
	var angle = time * rotation_speed + index_offset
	# Radius that pulses slightly
	var radius = base_radius * (1.0 + 0.2 * sin(time * 2.0))
	var offset = Vector2(cos(angle), sin(angle)) * radius
	
	# Move downward smoothly
	meteor.position.y += 120 * delta
	
	if meteor.has_meta("spawn_x"):
		meteor.position.x = meteor.get_meta("spawn_x") + offset.x
