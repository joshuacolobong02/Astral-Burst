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
	reset_pool_state()

func reset_pool_state():
	_is_exploding = false
	time_passed = 0.0
	show()
	set_physics_process(true)
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

func _physics_process(delta):
	if movement_strategy:
		movement_strategy.update(self, delta)

func update_movement(delta):
	if movement_strategy:
		movement_strategy.update(self, delta)

func _on_visible_on_screen_notifier_2d_screen_exited():
	_destroy()

func _on_body_entered(body):
	if _is_exploding: return
	if body is Player:
		if body.has_method("take_hit"):
			body.take_hit()
		else:
			body.die()
		explode()

func take_damage(_amount):
	if _is_exploding: return
	killed.emit(points, global_position)
	explode()

func explode():
	if _is_exploding: return
	_is_exploding = true
		
	var game = get_tree().current_scene
	if explosion_scene:
		var explosion: Node
		if game and "pool_manager" in game and is_instance_valid(game.pool_manager):
			explosion = game.pool_manager.get_node_from_pool(explosion_scene)
		else:
			explosion = explosion_scene.instantiate()
			
		if not explosion.get_parent():
			game.add_child.call_deferred(explosion)
		explosion.global_position = global_position
		explosion.scale = Vector2(0.5, 0.5) # Match the small meteor size
		if explosion.has_method("reset_pool_state"):
			explosion.reset_pool_state()
	
	if has_node("ExplosionSound"):
		var sound = $ExplosionSound
		if game and "sfx_manager" in game and is_instance_valid(game.sfx_manager):
			game.sfx_manager.play_sfx(sound.stream, sound.volume_db)
		else:
			# Fallback if no sfx_manager
			var temp_sfx = AudioStreamPlayer.new()
			temp_sfx.stream = sound.stream
			temp_sfx.volume_db = sound.volume_db
			temp_sfx.bus = &"SFX"
			game.add_child.call_deferred(temp_sfx)
			temp_sfx.play()
			temp_sfx.finished.connect(temp_sfx.queue_free)
	
	_destroy()

func _destroy():
	hide()
	set_physics_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	var game = get_tree().current_scene
	if game and "pool_manager" in game and is_instance_valid(game.pool_manager):
		game.pool_manager.return_to_pool(self, "res://scene/meteor_projectile.tscn")
	else:
		queue_free()

func set_texture(tex):
	set_meta("custom_texture", tex)
	if sprite:
		sprite.texture = tex
