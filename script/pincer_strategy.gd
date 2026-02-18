class_name PincerStrategy
extends MovementStrategy

var side := 1
var amplitude := 100.0
var frequency := 2.0
var time := 0.0

func _init(start_side: int = 1):
	side = start_side

func update(meteor: Node2D, delta: float):
	time += delta
	meteor.position.y += 200 * delta
	meteor.position.x += side * cos(time * frequency) * amplitude * delta
