class_name EnemyLaser extends Area2D

@export var speed = 700
@export var damage = 1

var direction := Vector2.DOWN
var _base_sprite_scale: Vector2
var _shoot_sfx = preload("res://asset/Bonus/sfx_laser1.ogg")

func _ready():
	_base_sprite_scale = $Sprite2D.scale
	z_as_relative = false
	z_index = 150 # Absolute top
	
	# Visual distinction: bright reddish-orange for enemy lasers
	self_modulate = Color(2.0, 0.4, 0.2, 1.0) 
	
	# Safe signal connections
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	var notifier = get_node_or_null("VisibleOnScreenNotifier2D")
	if notifier and not notifier.screen_exited.is_connected(_on_visible_on_screen_notifier_2d_screen_exited):
		notifier.screen_exited.connect(_on_visible_on_screen_notifier_2d_screen_exited)
	
	reset_pool_state()

func reset_pool_state():
	show()
	modulate.a = 1.0
	visible = true
	
	set_process(true)
	set_physics_process(true)
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	
	rotation = direction.angle() + PI/2
	queue_redraw() # Force fallback draw
	
	# Deferred sound check to allow global_position to be set first in shoot()
	call_deferred("_check_play_sound")

func _draw():
	# Fallback visualization in case sprite is invisible
	draw_rect(Rect2(-2, -20, 4, 40), Color(1, 0, 0, 0.5))

func _check_play_sound():
	if not is_inside_tree(): return
	var vs = get_viewport_rect()
	if vs.has_point(global_position):
		var game = get_tree().current_scene
		if game and "sfx_manager" in game and is_instance_valid(game.sfx_manager):
			game.sfx_manager.play_sfx(_shoot_sfx, -28.0)

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	_destroy()

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_hit"):
			body.take_hit()
		else:
			body.die()
		_destroy()

func _destroy():
	hide()
	set_physics_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	var game = get_tree().current_scene
	if game and "pool_manager" in game and is_instance_valid(game.pool_manager):
		game.pool_manager.return_to_pool(self, scene_file_path)
	else:
		queue_free()
