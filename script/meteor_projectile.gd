class_name MeteorProjectile extends Area2D

signal killed(points, pos)
@export var speed: float = 120.0
@export var damage: int = 1
@export var points: int = 50
@export var direction: Vector2 = Vector2.DOWN
@export var rotation_speed: float = 0.0

# Wave movement properties (supported by SimpleMovement strategy)
@export var wave_amplitude: float = 0.0
@export var wave_frequency: float = 0.0
@export var phase_offset: float = 0.0
var time_passed: float = 0.0

var movement_strategy: MovementStrategy = SimpleMovement.new()

var explosion_scene = preload("res://scene/explode_animate.tscn")
@onready var sprite = $Sprite2D

var _is_exploding = false

func _ready():
	# If texture was set before ready, apply it to the sprite
	if has_meta("custom_texture"):
		sprite.texture = get_meta("custom_texture")

func _physics_process(delta):
	if movement_strategy:
		movement_strategy.update(self, delta)

func update_movement(delta):
	if movement_strategy:
		movement_strategy.update(self, delta)

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_body_entered(body):
	if _is_exploding: return
	if body is Player:
		if body.has_method("take_hit"):
			body.take_hit()
		else:
			body.die()
		explode()
		queue_free()

func take_damage(_amount):
	if _is_exploding: return
	killed.emit(points, global_position)
	explode()
	queue_free()

func explode():
	if _is_exploding: return
	_is_exploding = true
		
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		explosion.scale = Vector2(0.5, 0.5) # Match the small meteor size
		get_tree().current_scene.call_deferred("add_child", explosion)
	
	if has_node("ExplosionSound"):
		var sound = $ExplosionSound
		var spawn_pos = global_position
		remove_child(sound)
		get_tree().current_scene.call_deferred("add_child", sound)
		sound.call_deferred("set_global_position", spawn_pos)
		sound.call_deferred("play")
		if not sound.finished.is_connected(sound.queue_free):
			sound.finished.connect(sound.queue_free)

func set_texture(tex):
	set_meta("custom_texture", tex)
	if sprite:
		sprite.texture = tex
