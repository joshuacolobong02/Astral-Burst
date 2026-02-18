class_name RingStrategy
extends MovementStrategy

var angle := 0.0
var expansion_speed := 120.0
var time := 0.0
var center_offset := Vector2.ZERO

func _init(start_angle: float = 0.0):
	angle = start_angle

func update(meteor: Node2D, delta: float):
	time += delta
	
	# Smoothly expanding radius with a bit of "breathing"
	var radius = (expansion_speed * time) * (1.0 + 0.1 * sin(time * 4.0))
	var dir = Vector2(cos(angle), sin(angle))
	
	# Move downward as a whole group
	center_offset.y += 80.0 * delta
	
	meteor.position = meteor.get_meta("spawn_pos") + center_offset + (dir * radius)
