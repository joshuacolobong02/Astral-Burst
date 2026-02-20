class_name BaseEnemy extends Area2D

signal killed(points, pos)
signal hit
signal laser_shot(pos, direction)
signal meteor_shot(pos, direction, scale)
signal despawned(node)

enum Type { LINEAR, ORBITAL, ELITE, INFINITY, SEEKER, STRATEGY, STRIKER, STATIONARY }
@export var type: Type = Type.STATIONARY

enum ProjectileType { LASER, METEOR }
@export var projectile_type: ProjectileType = ProjectileType.LASER

@export var speed = 150
@export var hp = 1
@export var points = 100

var movement_strategy: MovementStrategy

@onready var hp_label = $HPLabel
@onready var sprite = $Sprite2D

var is_dead = false
var is_spawning = false
var flash_modulate = Color.WHITE

static var hit_shader_res = preload("res://script/hit_outline.gdshader")
static var shared_hit_mat: ShaderMaterial
var current_hit_tween: Tween
var _base_scale: Vector2
var _sprite_base_pos: Vector2

# Seeker & Shooting logic
var velocity: Vector2 = Vector2.ZERO
var player: Node2D
var ai_shoot_timer := 0.0
@export var ai_shoot_interval := 1.5

static var _cached_viewport_rect: Rect2
static var _last_rect_update := -1

func _ready():
	add_to_group("enemy")
	if hp_label:
		hp_label.visible = false
	
	if sprite:
		_base_scale = sprite.scale
		_sprite_base_pos = sprite.position
	
	_apply_hit_shader()
	
	# Initial player search
	player = get_tree().get_first_node_in_group("player")
	
	# Randomize first shot
	ai_shoot_timer = randf_range(0.5, ai_shoot_interval)
	
	reset_pool_state()

func reset_pool_state():
	is_dead = false
	is_spawning = false
	visible = true
	set_process(true)
	set_physics_process(true)
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	if hp_label: hp_label.visible = false
	if sprite:
		sprite.scale = _base_scale
		sprite.position = _sprite_base_pos
		sprite.modulate = Color.WHITE
		sprite.set_instance_shader_parameter("hit_strength", 0.0)
		sprite.set_instance_shader_parameter("outline_width", 0.0)

func _apply_hit_shader():
	if sprite:
		if shared_hit_mat == null:
			shared_hit_mat = ShaderMaterial.new()
			shared_hit_mat.shader = hit_shader_res
		
		sprite.material = shared_hit_mat
		sprite.set_instance_shader_parameter("outline_color", Color.WHITE)
		sprite.set_instance_shader_parameter("outline_width", 0.0)
		sprite.set_instance_shader_parameter("hit_strength", 0.0)

func play_fly_in(target_pos: Vector2, duration: float = 1.0):
	is_spawning = true
	var start_pos = global_position
	
	# ARC PATH SETUP
	var mid_point = (start_pos + target_pos) / 2.0
	var dist = start_pos.distance_to(target_pos)
	var offset_dir = (target_pos - start_pos).rotated(PI/2).normalized()
	var control_point = mid_point + offset_dir * (dist * 0.3) * (1 if randf() > 0.5 else -1)
	
	rotation = (control_point - start_pos).angle() + PI/2
	
	# GHOST TRAIL (Simplified for performance)
	var flight_trail = Line2D.new()
	flight_trail.width = 8.0
	flight_trail.default_color = Color(0.2, 0.5, 1.0, 0.3)
	get_tree().current_scene.add_child.call_deferred(flight_trail)
	
	var tween = create_tween().set_parallel(true)
	
	tween.tween_method(func(t):
		var q0 = start_pos.lerp(control_point, t)
		var q1 = control_point.lerp(target_pos, t)
		var next_pos = q0.lerp(q1, t)
		
		var move_dir = (next_pos - global_position).normalized()
		if move_dir.length() > 0.01:
			var target_rot = move_dir.angle() + PI/2
			rotation = lerp_angle(rotation, target_rot, 0.15)
			
		global_position = next_pos
		flight_trail.add_point(next_pos)
		if flight_trail.get_point_count() > 15:
			flight_trail.remove_point(0)
			
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	tween.set_parallel(false)
	tween.tween_callback(func():
		is_spawning = false
		_fade_trail(flight_trail)
		_trigger_soft_landing(target_pos)
	)

func _fade_trail(trail: Line2D):
	var ft = create_tween()
	ft.tween_property(trail, "modulate:a", 0.0, 0.3)
	ft.tween_callback(trail.queue_free)

func _trigger_soft_landing(target_pos: Vector2):
	var final_rot = 0.0
	if is_instance_valid(player):
		var p_dir = (player.global_position - target_pos).normalized()
		final_rot = p_dir.angle() + PI/2
		
	var st = create_tween().set_parallel(true)
	st.tween_property(self, "rotation", final_rot, 0.5).set_trans(Tween.TRANS_SINE)
	st.tween_property(sprite, "scale", _base_scale, 0.4).from(_base_scale * 0.9)

func _physics_process(delta):
	if is_dead or is_spawning: return
	
	# Efficient player tracking
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	
	if movement_strategy:
		movement_strategy.update(self, delta)
	else:
		_apply_default_movement(delta)
				
	if type != Type.LINEAR:
		ai_shoot_timer -= delta
		if ai_shoot_timer <= 0:
			shoot()
			ai_shoot_timer = ai_shoot_interval
			
	if type == Type.STATIONARY and !is_dead and sprite:
		var bob_offset = sin(Time.get_ticks_msec() * 0.003) * 2.0
		sprite.position.y = _sprite_base_pos.y + bob_offset

func _apply_default_movement(delta):
	match type:
		Type.STATIONARY:
			if is_instance_valid(player):
				var target_dir = (player.global_position - global_position).normalized()
				rotation = lerp_angle(rotation, target_dir.angle() + PI/2, delta * 5.0)
		Type.LINEAR:
			global_position.y += speed * delta
		Type.SEEKER:
			if is_instance_valid(player):
				var target_dir = (player.global_position - global_position).normalized()
				velocity = velocity.lerp(target_dir * speed, delta * 3.0)
				global_position += velocity * delta
				rotation = velocity.angle() + PI/2
			else:
				global_position.y += speed * delta
		Type.STRIKER:
			if is_instance_valid(player):
				var target_y = 180.0 + (get_index() % 4) * 35.0
				if global_position.y < target_y:
					global_position.y += speed * delta * 0.5
				var dx = player.global_position.x - global_position.x
				velocity.x = lerp(velocity.x, clamp(dx * 0.05, -1.0, 1.0) * speed, delta * 2.0)
				global_position.x += velocity.x * delta
				rotation = lerp_angle(rotation, velocity.x * 0.005, delta * 5.0)
			else:
				global_position.y += speed * delta

func shoot():
	if is_dead or is_spawning: return
	
	# Static Viewport Cache
	var ticks = Engine.get_process_frames()
	if _last_rect_update != ticks:
		_cached_viewport_rect = get_viewport_rect().grow(100.0)
		_last_rect_update = ticks
		
	if !_cached_viewport_rect.has_point(global_position): return
	
	var dir = Vector2.DOWN
	if is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	
	if projectile_type == ProjectileType.METEOR:
		meteor_shot.emit(global_position, dir, Vector2.ONE)
	else:
		laser_shot.emit(global_position, dir)

func die():
	if current_hit_tween: current_hit_tween.kill()
	despawned.emit(self)
	hide()
	set_process(false)
	set_physics_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	var game = get_tree().current_scene
	if game and "pool_manager" in game and is_instance_valid(game.pool_manager):
		game.pool_manager.return_to_pool(self, scene_file_path)
	else:
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	die()

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_hit"):
			body.take_hit()
		else:
			body.die()
		if !is_dead:
			is_dead = true
			killed.emit(points, global_position)
		die()

func take_damage(amount):
	if is_dead or is_spawning: return
	hp -= amount
	if hp_label:
		hp_label.text = str(hp)
		hp_label.visible = true
	
	if sprite:
		if current_hit_tween: current_hit_tween.kill()
		current_hit_tween = create_tween()
		current_hit_tween.set_parallel(true)
		sprite.set_instance_shader_parameter("hit_strength", 1.0)
		sprite.set_instance_shader_parameter("outline_width", 2.0)
		current_hit_tween.tween_method(func(v): sprite.set_instance_shader_parameter("hit_strength", v), 1.0, 0.0, 0.2)
		current_hit_tween.tween_method(func(v): sprite.set_instance_shader_parameter("outline_width", v), 2.0, 0.0, 0.2)
		current_hit_tween.tween_property(sprite, "scale", _base_scale * 1.2, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		current_hit_tween.set_parallel(false)
		current_hit_tween.tween_property(sprite, "scale", _base_scale, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if hp <= 0:
		is_dead = true
		killed.emit(points, global_position)
		die()
	else:
		hit.emit()
