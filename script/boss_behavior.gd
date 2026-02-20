extends BaseEnemy

@export var enter_speed = 150
@export var settle_y = 250

const BOSS_MARGIN := 70.0  # Min distance from screen edges (boss radius ~60)
const ROAM_Y_MAX_RATIO := 0.5  # Boss stays in upper half of screen

# Movement properties
var target_pos: Vector2
var time_passed: float = 0.0
var roam_speed = 1.2
var roam_radius = Vector2(150.0, 80.0)
var has_settled = false
var _bounds: Rect2  # Cached playable area

# Phase Logic
var max_hp: int = 50
var is_desperate = false
var protected_phase := false  # BigBoss: invulnerable until formation guardians die
var protectors_alive := 0

# Shooting properties
var projectile_scene: PackedScene
var meteor_projectile_scene = preload("res://scene/meteor_projectile.tscn")
var shoot_interval_min: float = 1.2
var shoot_interval_max: float = 1.8

# Big Boss special projectiles
var moon_minion_scene = preload("res://scene/moon_guardian.tscn")
var mars_minion_scene = preload("res://scene/guardian_red.tscn")

# Unique Boss Properties
var boss_type = "Moon" # Default
var meteor_texture: Texture2D
var target_sprite_scale = Vector2(0.5, 0.5)
var is_shooting = false
var active_shoot_tween: Tween

var _is_dying = false

func _ready():
	# Solo Guardian HP
	hp = 50
	max_hp = hp
	
	# Default projectile
	projectile_scene = meteor_projectile_scene
	
	# Determine Boss Type
	if "Moon" in name:
		boss_type = "Moon"
		meteor_texture = load("res://asset/PNG/Meteors/MeteorRed1.png")
	elif "Mars" in name:
		boss_type = "Mars"
		meteor_texture = load("res://asset/PNG/Meteors/MeteorRed2.png")
	elif "Jupiter" in name:
		boss_type = "Jupiter"
		meteor_texture = load("res://asset/PNG/Meteors/MeteorRed3.png")
	elif "Saturn" in name:
		boss_type = "Saturn"
		meteor_texture = load("res://asset/PNG/Meteors/MeteorRed4.png")
	elif "Uranus" in name:
		boss_type = "Uranus"
		meteor_texture = load("res://asset/PNG/Meteors/MeteorRed5.png")
	elif "Neptune" in name:
		boss_type = "Neptune"
		meteor_texture = load("res://asset/PNG/Meteors/MeteorSilver3.png")
	elif "Scattered" in name:
		boss_type = "Scattered"
		meteor_texture = load("res://asset/PNG/Meteors/MeteorSilver5.png")
	elif "Oort" in name:
		boss_type = "Oort"
		meteor_texture = load("res://asset/PNG/Meteors/MeteorSilver1.png")
		target_sprite_scale = Vector2(1.5, 1.5)
	elif "Meteor" in name: # Big Boss
		boss_type = "Meteor"
		meteor_texture = load("res://asset/PNG/Meteors/MeteorYellow1.png")
		projectile_scene = meteor_projectile_scene
		hp = max(hp, 120)
		max_hp = hp
		protected_phase = true
	else:
		meteor_texture = load("res://asset/PNG/Meteors/MeteorRed1.png")
		
	# INITIAL STATE: Hidden for smooth spawn
	if sprite:
		sprite.modulate.a = 0.0
		sprite.scale = Vector2(0.1, 0.1)
		if target_sprite_scale == Vector2(0.5, 0.5) and sprite.scale != Vector2(0.1, 0.1):
			target_sprite_scale = sprite.scale
	
	add_to_group("boss")
	_update_bounds()
	settle_y = clampf(settle_y, _bounds.position.y + 50.0, _bounds.end.y - 50.0)
	roam_radius.x = minf(roam_radius.x, (_bounds.end.x - _bounds.position.x) * 0.5)
	roam_radius.y = minf(roam_radius.y, (_bounds.end.y - _bounds.position.y) * 0.4)
	if boss_type == "Meteor" and protected_phase:
		var formation = get_node_or_null("EscortFormation")
		if formation:
			protectors_alive = formation.get_child_count()
			for child in formation.get_children():
				if not child.tree_exited.is_connected(_on_formation_guardian_died):
					child.tree_exited.connect(_on_formation_guardian_died)
		$CollisionShape2D.set_deferred("disabled", true)
		if sprite:
			sprite.visible = false
	reset_shoot_timer()
	
	# Explicitly call super._ready to ensure pooling setup if any
	super._ready()

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
	
	# Difficulty Check: Half Life
	if !is_desperate and hp <= (max_hp / 2.0):
		_enter_desperation_phase()
	
	if !has_settled:
		if global_position.y < settle_y:
			global_position.y += enter_speed * delta
			global_position.x = clampf(global_position.x, _bounds.position.x, _bounds.end.x)
			if sprite:
				sprite.modulate.a = move_toward(sprite.modulate.a, 1.0, delta * 0.5)
				sprite.scale = sprite.scale.move_toward(target_sprite_scale, delta * 0.2)
		else:
			global_position = _clamp_to_bounds(Vector2(global_position.x, settle_y))
			has_settled = true
			target_pos = global_position
			if sprite:
				sprite.modulate.a = 1.0
				sprite.scale = target_sprite_scale
	else:
		time_passed += delta
		
		var hit_running = current_hit_tween != null and current_hit_tween.is_running()
		var shoot_running = active_shoot_tween != null and active_shoot_tween.is_running()
		
		# ROAMING MOVEMENT (clamped to playable bounds)
		if !shoot_running:
			var center_x = _bounds.get_center().x
			var speed_mod = 2.0 if is_desperate else 1.0
			var x_limit = center_x + (sin(time_passed * roam_speed * 0.5) * roam_radius.x)
			var y_limit = settle_y + (cos(time_passed * roam_speed * 0.8) * roam_radius.y)
			var target = _clamp_to_bounds(Vector2(x_limit, y_limit))
			global_position = _clamp_to_bounds(global_position.lerp(target, delta * roam_speed * speed_mod))
		
		if !hit_running and !shoot_running:
			var pulse_speed = 4.0 if is_desperate else 2.0
			var pulse = (sin(time_passed * pulse_speed) + 1.0) * 0.5
			if sprite:
				sprite.scale = target_sprite_scale + (target_sprite_scale * 0.05) * pulse
				if is_desperate:
					sprite.modulate = Color(1.5, 0.8, 0.8, 1.0).lerp(Color.WHITE, pulse)
		
		if !protected_phase:
			handle_shooting(delta)

func _on_formation_guardian_died():
	if is_dead or _is_dying: return
	protectors_alive -= 1
	if protectors_alive <= 0:
		_activate_meteor_boss()

func _activate_meteor_boss():
	protected_phase = false
	$CollisionShape2D.set_deferred("disabled", false)
	if sprite:
		sprite.visible = true
		sprite.modulate.a = 0.0
		sprite.scale = Vector2(0.1, 0.1)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "modulate:a", 1.0, 1.0)
		tween.tween_property(sprite, "scale", target_sprite_scale, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _enter_desperation_phase():
	is_desperate = true
	roam_radius *= 1.5
	roam_radius.x = minf(roam_radius.x, (_bounds.end.x - _bounds.position.x) * 0.5)
	roam_radius.y = minf(roam_radius.y, (_bounds.end.y - _bounds.position.y) * 0.4)
	shoot_interval_min *= 0.6
	shoot_interval_max *= 0.6
	
	# Visual/Audio feedback for phase change
	var scene = get_tree().current_scene
	if scene.has_method("shake_camera"):
		scene.shake_camera(15.0, 0.8)
	
	if sprite:
		var pt = create_tween()
		pt.tween_property(sprite, "modulate", Color(5.0, 0.5, 0.5, 1.0), 0.2)
		pt.tween_property(sprite, "modulate", Color.WHITE, 0.2)
		pt.set_loops(2)

func handle_shooting(delta):
	ai_shoot_timer -= delta
	if ai_shoot_timer <= 0:
		is_shooting = true
		if sprite:
			if active_shoot_tween:
				active_shoot_tween.kill()
				
			active_shoot_tween = create_tween()
			
			# Faster wind-up in desperation
			var anim_speed = 0.5 if is_desperate else 1.0
			
			active_shoot_tween.tween_property(sprite, "position:y", -60.0, 0.4 * anim_speed).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			active_shoot_tween.parallel().tween_property(sprite, "scale", target_sprite_scale * 0.75, 0.4 * anim_speed)
			active_shoot_tween.parallel().tween_property(sprite, "modulate", Color(2.0, 1.2, 1.2, 1.0), 0.4 * anim_speed)
			
			active_shoot_tween.tween_property(sprite, "position:y", 100.0, 0.15 * anim_speed).as_relative().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			active_shoot_tween.parallel().tween_property(sprite, "scale", target_sprite_scale * 1.4, 0.15 * anim_speed)
			active_shoot_tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.15 * anim_speed)
			
			active_shoot_tween.tween_callback(func():
				shoot_formation()
				var scene = get_tree().current_scene
				if scene.has_method("shake_camera"):
					var intensity = 10.0 if is_desperate else 5.0
					scene.shake_camera(intensity, 0.25)
			)
			
			active_shoot_tween.tween_property(sprite, "position:y", 0.0, 0.5 * anim_speed).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			active_shoot_tween.parallel().tween_property(sprite, "scale", target_sprite_scale, 0.5 * anim_speed)
			active_shoot_tween.tween_callback(func(): is_shooting = false)
		else:
			shoot_formation()
			is_shooting = false
			
		reset_shoot_timer()

func reset_shoot_timer():
	var interval_min = shoot_interval_min
	var interval_max = shoot_interval_max
	
	if boss_type == "Meteor":
		ai_shoot_timer = 2.0 if is_desperate else 3.0
	else:
		ai_shoot_timer = randf_range(interval_min, interval_max)

func shoot_formation():
	if boss_type == "Meteor":
		throw_moon_guardians_staggered()
		return
		
	match boss_type:
		"Moon": spawn_spread_pattern([-30, -15, 0, 15, 30])
		"Mars": spawn_spread_pattern([-5, 0, 5])
		"Jupiter": spawn_spread_pattern([-45, -30, -15, 0, 15, 30, 45])
		"Saturn": 
			var base = [0, 90, 180, 270, 45, 135, 225, 315]
			if is_desperate: base.append_array([22, 67, 112, 157, 202, 247, 292, 337])
			spawn_spread_pattern(base)
		"Uranus": 
			var count = 8 if is_desperate else 5
			var angles = []
			for i in count: angles.append(randf_range(-80, 80))
			spawn_spread_pattern(angles)
		"Neptune": spawn_spread_pattern([-40, -20, 0, 20, 40] if is_desperate else [-20, -10, 0, 10, 20])
		"Scattered":
			var count = 12 if is_desperate else 8
			var angles = []
			for i in count: angles.append(randf_range(-40, 40))
			spawn_spread_pattern(angles)
		"Oort":
			var base = [-60, -40, -20, 0, 20, 40, 60]
			if is_desperate: base.append_array([-70, -50, -30, -10, 10, 30, 50, 70])
			spawn_spread_pattern(base)
		_: spawn_spread_pattern([-30, 0, 30])

func throw_moon_guardians_staggered():
	_start_staggered_throw()

func _start_staggered_throw():
	if is_dead or _is_dying or !is_inside_tree(): return
	var angles = [-45, -30, -15, 0, 15, 30, 45]
	if is_desperate: angles.append_array([-60, 60])
	
	is_shooting = true
	
	if sprite:
		if active_shoot_tween: active_shoot_tween.kill()
		active_shoot_tween = create_tween()
		active_shoot_tween.tween_property(sprite, "scale", target_sprite_scale * 0.85, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		active_shoot_tween.parallel().tween_property(sprite, "modulate", Color(1.8, 1.2, 1.2, 1.0), 0.25).set_trans(Tween.TRANS_SINE)
		await active_shoot_tween.finished

	var delay = 0.12 if is_desperate else 0.18
	for i in range(angles.size()):
		if is_dead or _is_dying: break
		var angle = angles[i]
		if sprite:
			var recoil_amount = 12.0
			var recoil_tween = create_tween()
			recoil_tween.tween_property(sprite, "position:y", -recoil_amount, 0.08).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			recoil_tween.tween_property(sprite, "position:y", recoil_amount, 0.12).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		spawn_thrown_guardian(moon_minion_scene, angle)
		await get_tree().create_timer(delay).timeout
	
	if !is_dead and !_is_dying and sprite:
		if active_shoot_tween: active_shoot_tween.kill()
		active_shoot_tween = create_tween()
		active_shoot_tween.tween_property(sprite, "scale", target_sprite_scale, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		active_shoot_tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.5).set_trans(Tween.TRANS_SINE)
		active_shoot_tween.tween_callback(func(): is_shooting = false)
	else:
		is_shooting = false

func spawn_thrown_guardian(scene, angle, offset_x = 0):
	if !is_inside_tree() or is_dead or _is_dying: return
	var spawn_pos = _clamp_to_bounds(global_position + Vector2(offset_x, 0))
	
	var game = get_tree().current_scene
	var minion: Node
	if game and "pool_manager" in game and is_instance_valid(game.pool_manager):
		minion = game.pool_manager.get_node_from_pool(scene)
	else:
		minion = scene.instantiate()
		
	if "is_spawning" in minion: minion.is_spawning = false
	if not minion.get_parent():
		get_tree().current_scene.call_deferred("add_child", minion)
	
	minion.global_position = spawn_pos
	minion.z_index = 10
	
	var rad = deg_to_rad(angle + 90.0)
	var dir = Vector2(cos(rad), sin(rad))
	var launch_dist = 140.0
	var target_launch_pos = minion.global_position + dir * launch_dist
	
	minion.scale = Vector2(0.25, 0.25)
	minion.modulate.a = 0.9
	
	var target_speed = 550 if is_desperate else 480
	if "speed" in minion: minion.speed = 0
	if "hp" in minion: minion.hp = 4 if is_desperate else 3
	if "points" in minion: minion.points = 0
	if minion.has_method("set_direction"): minion.set_direction(dir)

	var final_guardian_scale = Vector2(1.5, 1.5)
	var launch_duration = 0.55
	var scale_duration = 0.5
	var speed_ramp_duration = 0.25

	var launch_tween = create_tween()
	launch_tween.set_parallel(true)
	launch_tween.tween_property(minion, "global_position", target_launch_pos, launch_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	launch_tween.tween_property(minion, "scale", final_guardian_scale, scale_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	launch_tween.tween_property(minion, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE)
	if "rotation" in minion:
		launch_tween.tween_property(minion, "rotation", dir.angle() + PI/2, launch_duration * 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	launch_tween.set_parallel(false)
	launch_tween.tween_property(minion, "speed", target_speed, speed_ramp_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	launch_tween.tween_callback(func(): 
		if is_instance_valid(minion):
			minion.scale = final_guardian_scale
	)

	if minion.has_signal("killed"):
		if game.has_method("_on_enemy_killed") and not minion.killed.is_connected(game._on_enemy_killed):
			minion.killed.connect(game._on_enemy_killed)
	if minion.has_signal("meteor_shot") and game.has_method("_on_enemy_meteor_shot"):
		if not minion.meteor_shot.is_connected(game._on_enemy_meteor_shot):
			minion.meteor_shot.connect(game._on_enemy_meteor_shot)

func spawn_spread_pattern(angles: Array):
	for angle in angles:
		var rad = deg_to_rad(angle + 90.0)
		var dir = Vector2(cos(rad), sin(rad))
		var spawn_pos = _clamp_to_bounds(global_position + Vector2(0, 40))
		meteor_shot.emit(spawn_pos, dir, Vector2.ONE)

func _on_visible_on_screen_notifier_2d_screen_exited():
	# Boss must emit killed so game state updates (spawn_minions, boss_spawned)
	if !is_dead and !_is_dying:
		is_dead = true
		killed.emit(points, global_position)
	super._on_visible_on_screen_notifier_2d_screen_exited()

func die():
	if _is_dying: return
	_is_dying = true
	if active_shoot_tween: active_shoot_tween.kill()
	super.die()
