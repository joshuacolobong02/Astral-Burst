class_name BaseEnemy extends Area2D

signal killed(points, pos)
signal hit

enum Type { LINEAR, ORBITAL, ELITE, INFINITY, SEEKER, STRATEGY, STRIKER, STATIONARY }
@export var type: Type = Type.STATIONARY

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
var enemy_laser_scene = load("res://scene/enemy_laser.tscn")

func _ready():
	if hp_label:
		hp_label.visible = false
	
	if sprite:
		_base_scale = sprite.scale
		_sprite_base_pos = sprite.position
	
	_apply_hit_shader()
	
	# Try to find player
	player = get_tree().current_scene.get_node_or_null("Player")
	
	# Randomize first shot
	ai_shoot_timer = randf_range(0.5, ai_shoot_interval)

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
	
	# 1. ARC PATH SETUP: Graceful curve based on distance
	var mid_point = (start_pos + target_pos) / 2.0
	var dist = start_pos.distance_to(target_pos)
	var offset_dir = (target_pos - start_pos).rotated(PI/2).normalized()
	var control_point = mid_point + offset_dir * (dist * 0.3) * (1 if randf() > 0.5 else -1)
	
	# Initial Look-at
	rotation = (control_point - start_pos).angle() + PI/2
	
	# 2. GHOST TRAIL: Ethereal blue trail
	var flight_trail = Line2D.new()
	flight_trail.width = 10.0
	flight_trail.default_color = Color(0.2, 0.5, 1.0, 0.4)
	flight_trail.gradient = Gradient.new()
	flight_trail.gradient.set_color(0, Color(0.2, 0.5, 1.0, 0.0))
	flight_trail.gradient.set_color(1, Color(0.4, 0.7, 1.0, 0.6))
	flight_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	flight_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	get_tree().current_scene.add_child(flight_trail)
	
	var tween = create_tween().set_parallel(true)
	
	# 3. SMOOTH FLIGHT: Quintic easing for premium feel
	tween.tween_method(func(t):
		var q0 = start_pos.lerp(control_point, t)
		var q1 = control_point.lerp(target_pos, t)
		var next_pos = q0.lerp(q1, t)
		
		# Smoothly rotate to face movement
		var move_dir = (next_pos - global_position).normalized()
		if move_dir.length() > 0.01:
			var target_rot = move_dir.angle() + PI/2
			rotation = lerp_angle(rotation, target_rot, 0.15)
			
		global_position = next_pos
		flight_trail.add_point(next_pos)
		if flight_trail.get_point_count() > 20:
			flight_trail.remove_point(0)
			
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	# 4. ARRIVAL TRANSITION
	tween.set_parallel(false)
	tween.tween_callback(func():
		is_spawning = false
		_fade_trail(flight_trail)
		_trigger_soft_landing(target_pos)
	)

func _fade_trail(trail: Line2D):
	var ft = create_tween()
	ft.tween_property(trail, "modulate:a", 0.0, 0.4)
	ft.tween_callback(trail.queue_free)

func _trigger_soft_landing(target_pos: Vector2):
	# Gentle stabilization
	var final_rot = 0.0
	if is_instance_valid(player):
		var p_dir = (player.global_position - target_pos).normalized()
		final_rot = p_dir.angle() + PI/2
		
	var st = create_tween().set_parallel(true)
	st.tween_property(self, "rotation", final_rot, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Subtle breath effect on arrival
	sprite.scale = _base_scale * 0.9
	st.tween_property(sprite, "scale", _base_scale, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Soft glow pulse
	sprite.set_instance_shader_parameter("hit_strength", 0.4)
	var gt = create_tween()
	gt.tween_method(func(v): sprite.set_instance_shader_parameter("hit_strength", v), 0.4, 0.0, 0.6)

func _physics_process(delta):
	if is_dead or is_spawning: return
	
	if !is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	
	if movement_strategy:
		movement_strategy.update(self, delta)
	else:
		if type == Type.STATIONARY:
			if is_instance_valid(player):
				var target_dir = (player.global_position - global_position).normalized()
				rotation = lerp_angle(rotation, target_dir.angle() + PI/2, delta * 5.0)
		elif type == Type.LINEAR:
			global_position.y += speed * delta
		elif type == Type.SEEKER:
			if is_instance_valid(player):
				var target_dir = (player.global_position - global_position).normalized()
				velocity = velocity.lerp(target_dir * speed, delta * 3.0)
				global_position += velocity * delta
				rotation = velocity.angle() + PI/2
			else:
				global_position.y += speed * delta
		elif type == Type.STRIKER:
			if is_instance_valid(player):
				var target_y = 180.0 + (get_index() % 4) * 35.0
				var move_speed = speed * delta
				if global_position.y < target_y:
					global_position.y += move_speed * 0.5
				var dx = player.global_position.x - global_position.x
				var strafe_force = clamp(dx * 0.05, -1.0, 1.0)
				velocity.x = lerp(velocity.x, strafe_force * speed, delta * 2.0)
				global_position.x += velocity.x * delta
				rotation = lerp_angle(rotation, velocity.x * 0.005, delta * 5.0)
			else:
				global_position.y += speed * delta
				
	if type == Type.SEEKER or type == Type.ELITE or type == Type.STRIKER or type == Type.STATIONARY:
		ai_shoot_timer -= delta
		if ai_shoot_timer <= 0:
			shoot()
			ai_shoot_timer = ai_shoot_interval
			
	var hit_running = current_hit_tween != null and current_hit_tween.is_running()
	if type == Type.STATIONARY and !is_dead and !hit_running and sprite:
		var bob_offset = sin(Time.get_ticks_msec() * 0.003 + get_instance_id()) * 2.0
		sprite.position.y = _sprite_base_pos.y + bob_offset

func shoot():
	if is_dead or is_spawning: return
	if !is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	var viewport_rect = get_viewport_rect()
	if !viewport_rect.has_point(global_position): return
	
	var laser = enemy_laser_scene.instantiate()
	laser.global_position = global_position
	var dir = Vector2.DOWN
	if is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	if laser.has_method("set"):
		laser.set("direction", dir)
	else:
		laser.rotation = dir.angle() + PI/2
	get_tree().current_scene.add_child(laser)

func die():
	if current_hit_tween:
		current_hit_tween.kill()
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

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
		if current_hit_tween:
			current_hit_tween.kill()
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
