class_name SpiralCollapseStrategy
extends MovementStrategy

var angle := 0.0
var rotation_speed := 4.0
var collapse_speed := 60.0
var radius := 350.0
var center_offset := Vector2.ZERO

func _init(start_angle: float = 0.0):
	angle = start_angle

func update(meteor: Node2D, delta: float):
	angle += rotation_speed * delta
	radius = max(0.0, radius - collapse_speed * delta)
	
	# Group movement downward
	center_offset.y += 60.0 * delta
	
	var offset = Vector2(cos(angle), sin(angle)) * radius
	if meteor.has_meta("spawn_pos"):
		meteor.position = meteor.get_meta("spawn_pos") + center_offset + offset
