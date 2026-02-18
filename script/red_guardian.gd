extends BaseEnemy

# Movement properties
var time_alive: float = 0.0
var horizontal_sway_speed: float = 2.0
var horizontal_sway_amount: float = 50.0
var initial_x: float = 0.0
var direction = Vector2.DOWN
var explosion_scene = preload("res://scene/explode_animate.tscn")
var projectile_scene = load("res://scene/enemy_laser.tscn")

# Shooting properties
var shoot_interval_min: float = 2.5
var shoot_interval_max: float = 4.5
var _attack_pattern_index: int = 0
var _is_dying = false
var is_shooting = false
var target_scale = Vector2(0.2, 0.2) # GuardianRed is typically smaller in its scene

func _ready():
	super._ready()
	initial_x = global_position.x
	reset_shoot_timer()
	if sprite:
		target_scale = sprite.scale

func _physics_process(delta):
	if _is_dying: return
	
	if direction != Vector2.DOWN:
		# If thrown, follow direction
		global_position += direction * speed * delta
	else:
		# Move down
		global_position.y += speed * delta
		
		# Add sway to make it harder to hit
		if !is_shooting:
			time_alive += delta
			var offset = sin(time_alive * horizontal_sway_speed) * horizontal_sway_amount
			global_position.x = initial_x + offset
	
	# Shooting logic
	ai_shoot_timer -= delta
	if ai_shoot_timer <= 0:
		perform_shoot_sequence()
		reset_shoot_timer()

func reset_shoot_timer():
	ai_shoot_timer = randf_range(shoot_interval_min, shoot_interval_max)

func perform_shoot_sequence():
	if is_shooting or _is_dying: return
	is_shooting = true
	
	if sprite:
		var throw_tween = create_tween()
		# Pull back
		throw_tween.tween_property(sprite, "position:y", -30.0, 0.25).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		throw_tween.parallel().tween_property(sprite, "scale", target_scale * 0.85, 0.25)
		
		# Snap forward
		throw_tween.tween_property(sprite, "position:y", 60.0, 0.1).as_relative().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		throw_tween.parallel().tween_property(sprite, "scale", target_scale * 1.25, 0.1)
		
		# Spawn projectlies during the snap
		throw_tween.tween_callback(shoot)
		
		# Recover
		throw_tween.tween_property(sprite, "position:y", 0.0, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		throw_tween.parallel().tween_property(sprite, "scale", target_scale, 0.4)
		throw_tween.tween_callback(func(): is_shooting = false)
	else:
		shoot()
		is_shooting = false

func shoot():
	if !projectile_scene or _is_dying: return
	
	var pattern = _attack_pattern_index % 3
	_attack_pattern_index += 1
	
	match pattern:
		0: # Fan Spread
			var angles = [-30, -15, 0, 15, 30]
			for angle in angles:
				_spawn_projectile(angle)
		1: # Forward Burst
			for i in range(5):
				_spawn_projectile(0, i * 35.0)
		2: # Circular Pulse
			var count = 8
			for i in range(count):
				var angle = (i * (360.0 / count)) - 90.0
				_spawn_projectile(angle)

func _spawn_projectile(angle_offset: float, pos_offset_y: float = 0.0):
	if _is_dying: return
	var proj = projectile_scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", proj)
	
	var spawn_pos = global_position + Vector2(0, 20 + pos_offset_y)
	proj.global_position = spawn_pos
	proj.z_index = z_index + 1
	
	# Aim in movement direction + offset
	var base_angle = direction.angle()
	var rad = base_angle + deg_to_rad(angle_offset)
	var dir = Vector2(cos(rad), sin(rad))
	
	if proj.has_method("set"):
		proj.set("direction", dir)
	else:
		proj.rotation = dir.angle() + PI/2

func set_direction(dir: Vector2):
	direction = dir

func die():
	if _is_dying: return
	_is_dying = true
	
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		explosion.scale = Vector2(0.5, 0.5)
		get_tree().current_scene.call_deferred("add_child", explosion)
	super.die()
