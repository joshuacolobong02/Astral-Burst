extends BaseEnemy

@export var enter_speed = 100
@export var settle_y = 250

const BOSS_MARGIN := 70.0
const ROAM_Y_MAX_RATIO := 0.5

# Movement
var target_pos: Vector2
var _bounds: Rect2
var time_passed: float = 0.0
var roam_radius = Vector2(140.0, 60.0)
var roam_speed = 1.0
var has_settled = false

# Phase Logic
var max_hp: int = 200
var is_desperate = false
var protected_phase = true
var protectors_alive = 4
var current_wave = 1

# Shooting (Solo Phase)
var projectile_scene = load("res://scene/enemy_laser.tscn")
var protector_scene = preload("res://scene/boss_protector.tscn")
var guard_textures = [
	preload("res://asset/PNG/Guardian/GuardianRed3.png"),
	preload("res://asset/PNG/Guardian/GuardianRed5.png"),
	preload("res://asset/PNG/Guardian/GuardianRed7.png"),
	preload("res://asset/PNG/Guardian/GuardianRed8.png")
]

var shoot_interval = 1.0 
var attack_count = 0
var is_activating = false
var is_shooting = false
var target_sprite_scale = Vector2(0.4, 0.4)
var active_shoot_tween: Tween

var _is_dying = false

func _ready():
	hp = 200 
	max_hp = 200
	if hp_label:
		hp_label.visible = false
	
	if sprite:
		sprite.visible = false
		sprite.modulate = Color(1, 1, 1, 0)
		sprite.scale = Vector2(0.1, 0.1)
		if sprite.scale != Vector2(0.1, 0.1):
			target_sprite_scale = sprite.scale
	
	$CollisionShape2D.set_deferred("disabled", true)
	
	add_to_group("boss")
	_update_bounds()
	settle_y = clampf(settle_y, _bounds.position.y + 50.0, _bounds.end.y - 50.0)
	roam_radius.x = minf(roam_radius.x, (_bounds.end.x - _bounds.position.x) * 0.5)
	roam_radius.y = minf(roam_radius.y, (_bounds.end.y - _bounds.position.y) * 0.4)
	var formation = get_node_or_null("EscortFormation")
	if formation:
		protectors_alive = formation.get_child_count()
		for child in formation.get_children():
			if not child.tree_exited.is_connected(_on_protector_died):
				child.tree_exited.connect(_on_protector_died)
	
	reset_shoot_timer()

func _update_bounds():
	var vs = get_viewport_rect().size
	_bounds = Rect2(BOSS_MARGIN, BOSS_MARGIN, vs.x - BOSS_MARGIN * 2.0, vs.y * ROAM_Y_MAX_RATIO)

func _clamp_to_bounds(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, _bounds.position.x, _bounds.end.x),
		clampf(pos.y, _bounds.position.y, _bounds.end.y)
	)

func _physics_process(delta):
	if _is_dying: return
	
	# Difficulty Check
	if !is_desperate and hp <= (max_hp / 2):
		_enter_desperation_phase()
		
	if !has_settled:
		if abs(global_position.y - settle_y) > 5.0:
			global_position.y = lerp(global_position.y, float(settle_y), delta * 2.0)
			global_position = _clamp_to_bounds(global_position)
			if sprite:
				sprite.visible = true
				sprite.modulate.a = move_toward(sprite.modulate.a, 1.0, delta * 0.5)
				sprite.scale = sprite.scale.move_toward(target_sprite_scale, delta * 0.2)
		else:
			global_position = _clamp_to_bounds(Vector2(global_position.x, settle_y))
			has_settled = true
			target_pos = global_position
			if sprite:
				sprite.visible = true
				sprite.modulate.a = 1.0
				sprite.scale = target_sprite_scale
	else:
		time_passed += delta
		
		var hit_running = current_hit_tween != null and current_hit_tween.is_running()
		var shoot_running = active_shoot_tween != null and active_shoot_tween.is_running()
		
		# ROAMING MOVEMENT (clamped to playable bounds)
		if !shoot_running:
			var center_x = _bounds.get_center().x
			var speed_mod = 2.5 if is_desperate else 1.0
			var x_limit = center_x + (sin(time_passed * roam_speed * 0.4) * roam_radius.x)
			var y_limit = settle_y + (cos(time_passed * roam_speed * 0.7) * roam_radius.y)
			var target = _clamp_to_bounds(Vector2(x_limit, y_limit))
			global_position = _clamp_to_bounds(global_position.lerp(target, delta * roam_speed * speed_mod))
		
		if !protected_phase and !hit_running and !shoot_running:
			var pulse_speed = 4.0 if is_desperate else 2.0
			var pulse = (sin(time_passed * pulse_speed) + 1.0) * 0.5
			if sprite:
				sprite.scale = target_sprite_scale + Vector2(0.03, 0.03) * pulse
				if is_desperate:
					sprite.modulate = Color(1.5, 0.7, 0.7, 1.0).lerp(Color.WHITE, pulse)
		
		if !protected_phase:
			ai_shoot_timer -= delta
			if ai_shoot_timer <= 0:
				attack_count += 1
				if attack_count % 3 == 0:
					throw_circle_attack()
				else:
					throw_guardians_attack()
				reset_shoot_timer()

func _enter_desperation_phase():
	is_desperate = true
	roam_radius *= 1.4
	roam_radius.x = minf(roam_radius.x, (_bounds.end.x - _bounds.position.x) * 0.5)
	roam_radius.y = minf(roam_radius.y, (_bounds.end.y - _bounds.position.y) * 0.4)
	shoot_interval *= 0.7
	
	var scene = get_tree().current_scene
	if scene.has_method("shake_camera"):
		scene.shake_camera(12.0, 0.6)
	
	if sprite:
		var pt = create_tween()
		pt.tween_property(sprite, "modulate", Color(4.0, 0.4, 0.4, 1.0), 0.15)
		pt.tween_property(sprite, "modulate", Color.WHITE, 0.15)
		pt.set_loops(3)

func _on_protector_died():
	if is_dead or _is_dying: return
	protectors_alive -= 1
	if protectors_alive <= 0:
		if current_wave == 1:
			spawn_second_wave()
		else:
			if !is_activating:
				activate_boss()

func spawn_second_wave():
	if current_wave == 2 or is_dead or _is_dying: return 
	current_wave = 2
	protectors_alive = 8 
	var max_r = minf(_bounds.end.x - _bounds.position.x, _bounds.end.y - _bounds.position.y) * 0.45
	var radius = minf(250.0, max_r)
	for i in range(8):
		var angle = i * (TAU / 8.0)
		var pos = Vector2(cos(angle), sin(angle)) * radius
		
		var prot = protector_scene.instantiate()
		var formation = get_node_or_null("EscortFormation")
		if formation:
			formation.call_deferred("add_child", prot)
			prot.position = pos
			prot.orbit_radius = radius
			prot.orbit_angle = angle
			prot.hp = 25 
			if "points" in prot: prot.points = 0
			prot.tree_exited.connect(_on_protector_died)
			
			var prot_sprite = prot.get_node_or_null("Sprite2D")
			if prot_sprite:
				prot_sprite.texture = guard_textures[i % guard_textures.size()]
			
			prot.scale = Vector2.ZERO
			prot.modulate.a = 0.0
			var et = create_tween().set_parallel(true)
			et.tween_property(prot, "scale", Vector2(1.0, 1.0), 0.8).set_trans(Tween.TRANS_BACK)
			et.tween_property(prot, "modulate:a", 1.0, 0.5)

func activate_boss():
	if is_activating: return
	is_activating = true
	protected_phase = false
	if sprite:
		sprite.visible = true
		sprite.modulate.a = 0.0
		sprite.scale = Vector2(0.01, 0.01)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "modulate:a", 1.0, 1.5)
		tween.tween_property(sprite, "scale", target_sprite_scale, 1.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		tween.set_parallel(false)
		tween.tween_callback($CollisionShape2D.set_deferred.bind("disabled", false))

func reset_shoot_timer():
	var ratio = clamp(float(hp) / 200.0, 0.0, 1.0)
	var speed_multiplier = 0.5 + 0.5 * ratio 
	ai_shoot_timer = shoot_interval * speed_multiplier

func throw_guardians_attack():
	if is_shooting or _is_dying: return
	is_shooting = true
	
	var angles = [-50, -30, -10, 10, 30, 50]
	if is_desperate: angles.append_array([-70, 70])
	
	if sprite:
		if active_shoot_tween: active_shoot_tween.kill()
		active_shoot_tween = create_tween()
		
		var anim_speed = 0.6 if is_desperate else 1.0
		
		active_shoot_tween.tween_property(sprite, "position:y", -40.0, 0.3 * anim_speed).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		active_shoot_tween.parallel().tween_property(sprite, "scale", target_sprite_scale * 0.8, 0.3 * anim_speed)
		active_shoot_tween.parallel().tween_property(sprite, "modulate", Color(2.5, 1.5, 1.5, 1), 0.3 * anim_speed)
		
		active_shoot_tween.tween_property(sprite, "position:y", 80.0, 0.1 * anim_speed).as_relative().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		active_shoot_tween.parallel().tween_property(sprite, "scale", target_sprite_scale * 1.3, 0.1 * anim_speed)
		active_shoot_tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.1 * anim_speed)
		
		active_shoot_tween.tween_callback(func(): 
			for i in range(angles.size()):
				spawn_thrown_protector(i, angles[i])
			var scene = get_tree().current_scene
			if scene.has_method("shake_camera"):
				var intensity = 10.0 if is_desperate else 6.0
				scene.shake_camera(intensity, 0.3)
		)
		
		active_shoot_tween.tween_property(sprite, "position:y", 0.0, 0.5 * anim_speed).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		active_shoot_tween.parallel().tween_property(sprite, "scale", target_sprite_scale, 0.5 * anim_speed)
		active_shoot_tween.tween_callback(func(): is_shooting = false)
	else:
		for i in range(angles.size()):
			spawn_thrown_protector(i, angles[i])
		is_shooting = false

func throw_circle_attack():
	if is_shooting or _is_dying: return
	is_shooting = true
	var count = 14 if is_desperate else 10 
	
	if sprite:
		if active_shoot_tween: active_shoot_tween.kill()
		active_shoot_tween = create_tween()
		
		var anim_speed = 0.6 if is_desperate else 1.0
		
		active_shoot_tween.tween_property(sprite, "scale", target_sprite_scale * 1.5, 0.4 * anim_speed).set_trans(Tween.TRANS_QUAD)
		active_shoot_tween.parallel().tween_property(sprite, "modulate", Color(3.0, 2.0, 2.0, 1), 0.4 * anim_speed)
		
		active_shoot_tween.tween_callback(func(): 
			for i in range(count):
				var angle = (i * (360.0 / count)) - 180.0
				spawn_thrown_protector(i, angle)
			var scene = get_tree().current_scene
			if scene.has_method("shake_camera"):
				var intensity = 12.0 if is_desperate else 8.0
				scene.shake_camera(intensity, 0.4)
		)
		
		active_shoot_tween.tween_property(sprite, "scale", target_sprite_scale, 0.6 * anim_speed).set_trans(Tween.TRANS_ELASTIC)
		active_shoot_tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.6 * anim_speed)
		active_shoot_tween.tween_callback(func(): is_shooting = false)
	else:
		for i in range(count):
			var angle = (i * (360.0 / count)) - 180.0
			spawn_thrown_protector(i, angle)
		is_shooting = false

func spawn_thrown_protector(index, angle):
	if !is_inside_tree() or is_dead or _is_dying: return
	var proj = protector_scene.instantiate()
	if "is_spawning" in proj: proj.is_spawning = false
	get_tree().current_scene.call_deferred("add_child", proj)
	
	proj.global_position = global_position
	proj.z_index = 10 
	
	var rad = deg_to_rad(angle + 90.0)
	var dir = Vector2(cos(rad), sin(rad))
	proj.direction = dir
	
	var target_launch_pos = proj.global_position + dir * 150
	proj.scale = Vector2(0.3, 0.3)
	proj.modulate.a = 1.0
	
	var prot_sprite = proj.get_node_or_null("Sprite2D")
	if prot_sprite:
		prot_sprite.texture = guard_textures[index % guard_textures.size()]
	
	var target_speed = 500 if is_desperate else 400
	proj.speed = 0 
	proj.hp = 4 if is_desperate else 3
	proj.points = 0
	proj.orbit_speed = 0 
	proj.independent = true 
	
	var final_proj_scale = Vector2(1.5, 1.5)

	var launch_tween = create_tween()
	launch_tween.set_parallel(true)
	launch_tween.tween_property(proj, "global_position", target_launch_pos, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	launch_tween.tween_property(proj, "scale", final_proj_scale, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	launch_tween.tween_property(proj, "rotation", proj.rotation + TAU, 0.5)
	
	launch_tween.set_parallel(false)
	launch_tween.tween_property(proj, "speed", target_speed, 0.1)
	
	launch_tween.tween_callback(func():
		if is_instance_valid(proj):
			proj.scale = final_proj_scale
	)

func _on_visible_on_screen_notifier_2d_screen_exited():
	if !is_dead and !_is_dying:
		is_dead = true
		killed.emit(points, global_position)
	super._on_visible_on_screen_notifier_2d_screen_exited()

func die():
	if _is_dying: return
	_is_dying = true
	if active_shoot_tween: active_shoot_tween.kill()
	super.die()
