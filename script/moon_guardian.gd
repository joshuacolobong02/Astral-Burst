extends BaseEnemy

var direction = Vector2.DOWN
var explosion_scene = preload("res://scene/explode_animate.tscn")
var projectile_scene = preload("res://scene/meteor_projectile.tscn")

var time_passed = 0.0
var hover_offset = Vector2.ZERO
var spawn_progress = 0.0
var _is_dying = false

# Phase Logic
var max_hp: int = 15
var is_desperate = false

# Shooting properties
var shoot_interval_min: float = 1.5
var shoot_interval_max: float = 3.0
var is_shooting = false
var target_scale = Vector2(0.3, 0.3)

func _ready():
	super._ready()
	is_spawning = true 
	time_passed = randf() * TAU
	if hp_label:
		hp_label.visible = false
	
	max_hp = hp if hp > 0 else 15
	
	if is_spawning:
		if modulate.a > 0.9: 
			modulate.a = 0.0
		if scale.x > 0.1: 
			scale = Vector2(0.1, 0.1)
	
	reset_shoot_timer()

func _physics_process(delta):
	if _is_dying: return
	
	# Difficulty Check
	if !is_desperate and hp <= (max_hp / 2):
		_enter_desperation_phase()
	
	if is_spawning:
		spawn_progress += delta * 2.0 
		modulate.a = move_toward(modulate.a, 1.0, delta * 2.0)
		scale = scale.move_toward(target_scale, delta * 0.6)
		if spawn_progress >= 1.0:
			is_spawning = false
			modulate.a = 1.0
			scale = target_scale
		return 

	time_passed += delta
	
	var speed_mod = 2.0 if is_desperate else 1.0
	
	# Enhanced Swaying movement
	if !is_shooting:
		# Dynamic Swaying
		hover_offset.x = sin(time_passed * 2.5 * speed_mod) * 40.0
		hover_offset.y = cos(time_passed * 1.8 * speed_mod) * 20.0
		global_position += (direction * speed * delta) + (hover_offset * delta * 5.0)
		rotation += (2.0 if !is_desperate else 5.0) * delta
	else:
		global_position += direction * speed * delta
		rotation += (1.0 if !is_desperate else 3.0) * delta
	
	if is_desperate:
		modulate = Color(1.5, 0.6, 0.6, 1.0).lerp(Color.WHITE, (sin(time_passed * 8.0) + 1.0) * 0.5)
	
	# Shooting logic
	ai_shoot_timer -= delta
	if ai_shoot_timer <= 0:
		perform_shoot_sequence()
		reset_shoot_timer()

func _enter_desperation_phase():
	is_desperate = true
	shoot_interval_min *= 0.5
	shoot_interval_max *= 0.5
	speed *= 1.5

func reset_shoot_timer():
	ai_shoot_timer = randf_range(shoot_interval_min, shoot_interval_max)

func perform_shoot_sequence():
	if is_shooting or _is_dying: return
	is_shooting = true
	
	if sprite:
		var throw_tween = create_tween()
		var anim_speed = 0.6 if is_desperate else 1.0
		
		# 1. Wind up
		throw_tween.tween_property(sprite, "position:y", -20.0, 0.2 * anim_speed).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		throw_tween.parallel().tween_property(sprite, "scale", target_scale * 0.8, 0.2 * anim_speed)
		
		# 2. Lunge
		throw_tween.tween_property(sprite, "position:y", 40.0, 0.1 * anim_speed).as_relative().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		throw_tween.parallel().tween_property(sprite, "scale", target_scale * 1.2, 0.1 * anim_speed)
		
		# 3. Trigger Spawn
		throw_tween.tween_callback(shoot)
		
		# 4. Recover
		throw_tween.tween_property(sprite, "position:y", 0.0, 0.3 * anim_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		throw_tween.parallel().tween_property(sprite, "scale", target_scale, 0.3 * anim_speed)
		throw_tween.tween_callback(func(): is_shooting = false)
	else:
		shoot()
		is_shooting = false

func shoot():
	if _is_dying: return
	
	var angles = [-20, 0, 20]
	if is_desperate: angles = [-35, -15, 0, 15, 35]
	
	for angle in angles:
		var base_angle = direction.angle() if direction != Vector2.ZERO else PI/2
		var rad = base_angle + deg_to_rad(angle)
		var dir = Vector2(cos(rad), sin(rad))
		meteor_shot.emit(global_position, dir, Vector2(0.6, 0.6))

func set_direction(dir: Vector2):
	direction = dir

func die():
	if _is_dying: return
	_is_dying = true
	
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		explosion.scale = Vector2(0.8, 0.8) 
		get_tree().current_scene.call_deferred("add_child", explosion)
		
		if get_tree().current_scene.has_method("shake_camera"):
			get_tree().current_scene.shake_camera(3.0, 0.15)
			
	super.die()
