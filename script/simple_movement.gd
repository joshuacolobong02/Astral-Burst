class_name SimpleMovement
extends MovementStrategy

func update(meteor: Node2D, delta: float):
	var dir = Vector2.DOWN
	var speed = 400.0
	
	if "direction" in meteor:
		dir = meteor.direction
	if "speed" in meteor:
		speed = meteor.speed
		
	var velocity = dir * speed
	
	# Apply wave movement if properties exist
	if "wave_amplitude" in meteor and meteor.wave_amplitude > 0:
		if "time_passed" in meteor:
			meteor.time_passed += delta
			var perpendicular = Vector2(-dir.y, dir.x)
			var wave_offset = perpendicular * cos((meteor.time_passed * meteor.wave_frequency) + meteor.phase_offset) * meteor.wave_amplitude * meteor.wave_frequency
			velocity += wave_offset
		
	meteor.position += velocity * delta
	
	if "rotation_speed" in meteor and meteor.rotation_speed != 0:
		meteor.rotation += meteor.rotation_speed * delta
