class_name CrossSweepStrategy
extends MovementStrategy

var velocity := Vector2(200, 150)

func _init(dir: Vector2 = Vector2(200, 150)):
	velocity = dir

func update(meteor: Node2D, delta: float):
	meteor.position += velocity * delta
