class_name DiveMovement
extends MovementStrategy

var target_position: Vector2
var target_player: Node2D
var velocity: Vector2 = Vector2.ZERO

func _init(pos: Vector2 = Vector2.ZERO):
	target_position = pos

func update(meteor: Node2D, delta: float):
	var target = target_position
	if is_instance_valid(target_player):
		target = target_player.global_position
	
	var dir = (target - meteor.global_position).normalized()
	var speed = 300.0
	if "speed" in meteor:
		speed = meteor.speed
		
	# Add some steering feel
	velocity = velocity.lerp(dir * speed * 1.5, delta * 2.0)
	meteor.global_position += velocity * delta
	
	# Rotate to face direction
	meteor.rotation = velocity.angle() + PI/2
