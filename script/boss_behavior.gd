extends BaseEnemy

@export var enter_speed = 150
@export var settle_y = 250

# Movement properties
var target_pos: Vector2
var time_passed: float = 0.0
var roam_speed = 1.2
var roam_radius = Vector2(150.0, 80.0)
var has_settled = false

# Phase Logic
var max_hp: int = 50
var is_desperate = false

# Shooting properties
var projectile_scene = load("res://scene/meteor_projectile.tscn")
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
		hp = 120
		max_hp = 120
	else:
		meteor_texture = load("res://asset/PNG/Meteors/MeteorRed1.png")
		
	# INITIAL STATE: Hidden for smooth spawn
	if sprite:
		sprite.modulate.a = 0.0
		sprite.scale = Vector2(0.1, 0.1)
		if target_sprite_scale == Vector2(0.5, 0.5) and sprite.scale != Vector2(0.1, 0.1):
			target_sprite_scale = sprite.scale
	
	reset_shoot_timer()

func _physics_process(delta):
	if _is_dying: return
	
	# Difficulty Check: Half Life
	if !is_desperate and hp <= (max_hp / 2):
		_enter_desperation_phase()
	
	if !has_settled:
		if global_position.y < settle_y:
			global_position.y += enter_speed * delta
			if sprite:
				sprite.modulate.a = move_toward(sprite.modulate.a, 1.0, delta * 0.5)
				sprite.scale = sprite.scale.move_toward(target_sprite_scale, delta * 0.2)
		else:
			global_position.y = settle_y
			has_settled = true
			target_pos = global_position
			if sprite:
				sprite.modulate.a = 1.0
				sprite.scale = target_sprite_scale
	else:
		time_passed += delta
		
		var hit_running = current_hit_tween != null and current_hit_tween.is_running()
		var shoot_running = active_shoot_tween != null and active_shoot_tween.is_running()
		
		# ROAMING MOVEMENT
		if !shoot_running:
			var speed_mod = 2.0 if is_desperate else 1.0
			var x_limit = 201.0 + (sin(time_passed * roam_speed * 0.5) * roam_radius.x)
			var y_limit = settle_y + (cos(time_passed * roam_speed * 0.8) * roam_radius.y)
			var target = Vector2(x_limit, y_limit)
			global_position = global_position.lerp(target, delta * roam_speed * speed_mod)
		
		if !hit_running and !shoot_running:
			var pulse_speed = 4.0 if is_desperate else 2.0
			var pulse = (sin(time_passed * pulse_speed) + 1.0) * 0.5
			if sprite:
				sprite.scale = target_sprite_scale + (target_sprite_scale * 0.05) * pulse
				if is_desperate:
					sprite.modulate = Color(1.5, 0.8, 0.8, 1.0).lerp(Color.WHITE, pulse)
		
		handle_shooting(delta)

func _enter_desperation_phase():
	is_desperate = true
	roam_radius *= 1.5
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
		
	if !projectile_scene: return
	
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
		active_shoot_tween.tween_property(sprite, "scale", target_sprite_scale * 0.8, 0.3).set_trans(Tween.TRANS_QUAD)
		active_shoot_tween.parallel().tween_property(sprite, "modulate", Color(2.0, 1.5, 1.5, 1.0), 0.3)
		await active_shoot_tween.finished

	var delay = 0.1 if is_desperate else 0.15
	for angle in angles:
		if is_dead or _is_dying: break
		
		if sprite:
			var recoil_tween = create_tween()
			recoil_tween.tween_property(sprite, "position:y", -15.0, 0.05).as_relative()
			recoil_tween.tween_property(sprite, "position:y", 15.0, 0.05).as_relative()
		
		spawn_thrown_guardian(moon_minion_scene, angle)
		await get_tree().create_timer(delay).timeout
	
	if !is_dead and !_is_dying and sprite:
		if active_shoot_tween: active_shoot_tween.kill()
		active_shoot_tween = create_tween()
		active_shoot_tween.tween_property(sprite, "scale", target_sprite_scale, 0.5).set_trans(Tween.TRANS_ELASTIC)
		active_shoot_tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.5)
		active_shoot_tween.tween_callback(func(): is_shooting = false)
	else:
		is_shooting = false

func spawn_thrown_guardian(scene, angle, offset_x = 0):
	if !is_inside_tree() or is_dead or _is_dying: return 
	var minion = scene.instantiate()
	if "is_spawning" in minion: minion.is_spawning = false
	get_tree().current_scene.call_deferred("add_child", minion)
	
	minion.global_position = global_position + Vector2(offset_x, 0)
	minion.z_index = 10
	
	var rad = deg_to_rad(angle + 90.0)
	var dir = Vector2(cos(rad), sin(rad))
	var target_launch_pos = minion.global_position + dir * 150
	
	minion.scale = Vector2(0.3, 0.3)
	minion.modulate.a = 1.0
	
	var target_speed = 550 if is_desperate else 480
	if "speed" in minion: minion.speed = 0
	if "hp" in minion: minion.hp = 4 if is_desperate else 3
	if "points" in minion: minion.points = 0
	if minion.has_method("set_direction"): minion.set_direction(dir)

	var final_guardian_scale = Vector2(1.5, 1.5)

	var launch_tween = create_tween()
	launch_tween.set_parallel(true)
	launch_tween.tween_property(minion, "global_position", target_launch_pos, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	launch_tween.tween_property(minion, "scale", final_guardian_scale, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	launch_tween.set_parallel(false)
	launch_tween.tween_property(minion, "speed", target_speed, 0.1)
	
	launch_tween.tween_callback(func(): 
		if is_instance_valid(minion):
			minion.scale = final_guardian_scale
	)

	if minion.has_signal("killed"):
		var game = get_tree().current_scene
		if game.has_method("_on_enemy_killed"):
			minion.killed.connect(game._on_enemy_killed)

func spawn_spread_pattern(angles: Array):
	for angle in angles:
		var proj = projectile_scene.instantiate()
		proj.set_texture(meteor_texture)
		if "points" in proj: proj.points = 0
		get_tree().current_scene.call_deferred("add_child", proj)
		
		if proj.has_signal("killed"):
			var game = get_tree().current_scene
			if game.has_method("_on_enemy_killed"):
				proj.killed.connect(game._on_enemy_killed)
				
		proj.global_position = global_position + Vector2(0, 40)
		proj.z_index = z_index + 1
		var rad = deg_to_rad(angle + 90.0) 
		proj.direction = Vector2(cos(rad), sin(rad))
		
		var base_scale = 2.0 if is_desperate else 1.5
		proj.scale = Vector2(base_scale, base_scale)
		
		if boss_type == "Oort":
			proj.scale = Vector2(2.5, 2.5) if is_desperate else Vector2(2.0, 2.0)

func die():
	if _is_dying: return
	_is_dying = true
	if active_shoot_tween: active_shoot_tween.kill()
	super.die()
