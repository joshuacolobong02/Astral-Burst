extends Node2D

@export var enemy_scenes: Array[PackedScene] = []

@onready var timer = $EnemySpawnTimer
@onready var enemy_container = $EnemyContainer
@onready var laser_container = $LaserContainer
@onready var hud = $UILayer/HUD
@onready var gos = $UILayer/GameOverScreen
@onready var player = $Player
@onready var pb = $ParallaxBackground
@onready var start_menu = $UILayer/StartMenu
@onready var intro_earth = $IntroEarth
@onready var camera = $Camera2D

@onready var hit_sound = $SFX/HitSound
@onready var explode_sound = $SFX/ExplodeSound
@onready var music_player = $SFX/MusicPlayer
@onready var game_over_sound = $SFX/GameOverSound
@onready var music_manager = $MusicManager

# Backgrounds
@onready var moon_layer = $ParallaxBackground/MoonLayer
@onready var moon_sprite = $ParallaxBackground/MoonLayer/Moon
@onready var earth_layer = $ParallaxBackground/EarthLayer
@onready var earth_sprite = $ParallaxBackground/EarthLayer/Earth
@onready var mars_layer = $ParallaxBackground/MarsLayer
@onready var mars_sprite = $ParallaxBackground/MarsLayer/Mars
@onready var mars_moon = $ParallaxBackground/MarsLayer/MarsMoon
@onready var asteroid_belt_layer = $ParallaxBackground/AsteroidBeltLayer
@onready var asteroid_belt = $ParallaxBackground/AsteroidBeltLayer/AsteroidBelt

@onready var jupiter_layer = $ParallaxBackground/JupiterLayer
@onready var jupiter_sprite = $ParallaxBackground/JupiterLayer/Jupiter
@onready var saturn_layer = $ParallaxBackground/SaturnLayer
@onready var saturn_sprite = $ParallaxBackground/SaturnLayer/Saturn
@onready var uranus_layer = $ParallaxBackground/UranusLayer
@onready var uranus_sprite = $ParallaxBackground/UranusLayer/Uranus
@onready var neptune_layer = $ParallaxBackground/NeptuneLayer
@onready var neptune_sprite = $ParallaxBackground/NeptuneLayer/Neptune
@onready var scattered_layer = $ParallaxBackground/ScatteredLayer
@onready var scattered_sprite = $ParallaxBackground/ScatteredLayer/Scattered
@onready var oort_layer = $ParallaxBackground/OortCloudLayer
@onready var oort_sprite = $ParallaxBackground/OortCloudLayer/Sprite2D

var explosion_scene = preload("res://scene/explode_animate.tscn")
var explosion_boss_scene = preload("res://scene/explosion_boss.tscn")
var laser_scene = preload("res://scene/laser.tscn")
var player_scene = preload("res://scene/player.tscn")

# Bosses
var moon_boss_scene = preload("res://scene/moon_boss.tscn")
var moon_guardian_scene = preload("res://scene/moon_guardian.tscn")
var mars_guardian_scene = preload("res://scene/mars_guardian.tscn")
var moon_guardian_orbital_scene = preload("res://scene/moon_guardian_orbital.tscn")
var mars_guardian_orbital_scene = preload("res://scene/mars_guardian_orbital.tscn")
var meteor_boss_scene = preload("res://scene/meteor_boss.tscn")
var meteor_boss_2_scene = preload("res://scene/meteor_boss_2.tscn")
var guardian_red_scene = preload("res://scene/guardian_red.tscn")

var jupiter_boss_scene = preload("res://scene/jupiter_boss.tscn")
var jupiter_guardian_orbital_scene = preload("res://scene/jupiter_guardian_orbital.tscn")
var saturn_boss_scene = preload("res://scene/saturn_boss.tscn")
var saturn_guardian_orbital_scene = preload("res://scene/saturn_guardian_orbital.tscn")
var uranus_boss_scene = preload("res://scene/uranus_boss.tscn")
var uranus_guardian_orbital_scene = preload("res://scene/uranus_guardian_orbital.tscn")
var neptune_boss_scene = preload("res://scene/neptune_boss.tscn")
var neptune_guardian_orbital_scene = preload("res://scene/neptune_guardian_orbital.tscn")
var scattered_boss_scene = preload("res://scene/scattered_boss.tscn")
var scattered_guardian_orbital_scene = preload("res://scene/scattered_guardian_orbital.tscn")
var oort_boss_scene = preload("res://scene/oort_boss.tscn")

# Enemies
var basic_enemy_scene = preload("res://scene/enemy.tscn")
var diver_enemy_scene = preload("res://scene/diver_enemy.tscn")
var large_enemy_scene = preload("res://scene/large_enemy.tscn")

var moon_enemy_1 = preload("res://scene/enemy_1.tscn")
var moon_enemy_2 = preload("res://scene/enemy_2.tscn")
var enemy_ship_scene = preload("res://scene/enemy_ship.tscn")
var meteor_projectile_scene = preload("res://scene/meteor_projectile.tscn")

# Powerups
var laser_boost_scene 
var shield_boost_scene 
var coin_boost_scene 
var speed_boost_scene 

var fleet_controller: Node2D = null
var powerup_container: Node2D = null
var boost_manager: BoostManager = null

enum Stage { SPACE, MOON, MARS, ASTEROID_BELT, JUPITER, SATURN, URANUS, NEPTUNE, SCATTERED, KUIPER_BELT, OORT_CLOUD }
var current_stage = Stage.SPACE
var time_elapsed = 0.0
var boss_spawned = false
var current_formation_index = 0
var formation_stage = 0 
var formation_counter = 0

var score := 0:
	set(value):
		score = value
		if hud:
			hud.score = score
		if score > high_score:
			high_score = score
		check_stage_transition()

var lives := 3:
	set(value):
		lives = value
		if hud:
			hud.update_lives(lives)
		
var high_score
var game_started = false
var is_paused = false
var _wave_active = false
var _is_waiting_for_next_wave = false
var _is_transitioning = false
var _ambient_meteor_timer = 0.0

var scroll_speed = 600
var drift_speed = 5
var _manual_scroll_offset := Vector2.ZERO
var _last_meteor_patterns: Array[String] = []
var _planet_layers_config: Array[Dictionary] = []
var _laser_pool: Array[Node] = []

@onready var death_blur = $DeathBlur
@onready var death_flash = $DeathFlash

var _shake_intensity := 0.0
var _shake_duration := 0.0
var _launch_tween: Tween

const WAVE_SEQUENCE = [
	"V", "DIAMOND", "SQUAD", "X_PATTERN", "CIRCLE", 
	"DOUBLE_V", "HEXAGON", "GRID", "WAVE", "CROSS",
	"SCATTER", "WALL", "DIAGONAL", "SPIRAL", "SQUAD"
]

func _ready():
	reset_game_state()
	process_mode = PROCESS_MODE_ALWAYS 
	
	_planet_layers_config = [
		{"layer": moon_layer, "sprite": moon_sprite, "rot": 0.04, "depth": 0.1},
		{"layer": earth_layer, "sprite": earth_sprite, "rot": 0.02, "depth": 0.12},
		{"layer": mars_layer, "sprite": mars_sprite, "rot": 0.06, "depth": 0.15},
		{"layer": asteroid_belt_layer, "sprite": asteroid_belt, "rot": 0.03, "depth": 0.08},
		{"layer": jupiter_layer, "sprite": jupiter_sprite, "rot": 0.05, "depth": 0.1},
		{"layer": saturn_layer, "sprite": saturn_sprite, "rot": 0.03, "depth": 0.09},
		{"layer": uranus_layer, "sprite": uranus_sprite, "rot": 0.07, "depth": 0.08},
		{"layer": neptune_layer, "sprite": neptune_sprite, "rot": 0.04, "depth": 0.07},
		{"layer": scattered_layer, "sprite": scattered_sprite, "rot": 0.02, "depth": 0.06},
	]
	
	for p in _planet_layers_config:
		p.layer.motion_scale = Vector2.ZERO
	
	laser_boost_scene = load("res://scene/laser_boost.tscn")
	shield_boost_scene = load("res://scene/shield_boost.tscn")
	coin_boost_scene = load("res://scene/coin_boost.tscn")
	speed_boost_scene = load("res://scene/speed_boost.tscn")

	_warm_up_resources()
	
	var save_file = FileAccess.open("user://save.data", FileAccess.READ)
	if save_file!=null: high_score = save_file.get_32()
	else: high_score = 0; save_game()
	
	# Use self. to trigger setters
	self.score = 0
	self.lives = 3
	hud.visible = false
	timer.stop()
	player.set_process(false)
	player.set_physics_process(false)
	
	moon_layer.visible = false; earth_layer.visible = false; mars_layer.visible = false
	asteroid_belt_layer.visible = false; jupiter_layer.visible = false; saturn_layer.visible = false
	uranus_layer.visible = false; neptune_layer.visible = false; scattered_layer.visible = false; oort_layer.visible = false
	
	if player: player.killed.connect(_on_player_killed); player.laser_shot.connect(_on_player_laser_shot)
	if hud: hud.settings_pressed.connect(toggle_pause)
	if start_menu: start_menu.start_game.connect(_on_start_game); start_menu.countdown_started.connect(_on_countdown_started)
	if gos: gos.restart.connect(_on_restart_requested)
	
	if intro_earth: intro_earth.position = Vector2(201, 874); intro_earth.visible = true; intro_earth.modulate.a = 1.0
	player.global_position = Vector2(201, 874); camera.zoom = Vector2(1.2, 1.2)
	
	fleet_controller = Node2D.new(); fleet_controller.set_script(load("res://script/fleet_controller.gd"))
	fleet_controller.name = "FleetController"; add_child(fleet_controller)
	
	powerup_container = Node2D.new(); powerup_container.name = "PowerupContainer"; add_child(powerup_container)
	
	# INITIALIZE BOOST MANAGER
	boost_manager = BoostManager.new()
	boost_manager.set_script(load("res://script/boost_manager.gd"))
	boost_manager.laser_boost_scene = load("res://scene/laser_boost.tscn")
	boost_manager.shield_boost_scene = load("res://scene/shield_boost.tscn")
	boost_manager.speed_boost_scene = load("res://scene/speed_boost.tscn")
	add_child(boost_manager)
	boost_manager.setup(player, powerup_container)
	
	timer.one_shot = true

func _process(delta):
	if Input.is_action_just_pressed("quit"): get_tree().quit()
	elif Input.is_action_just_pressed("reset"): reset_game_state(); get_tree().reload_current_scene()
	elif InputMap.has_action("pause") and Input.is_action_just_pressed("pause"): toggle_pause()
	if is_paused: return
	var stage_speed_mult = 1.0 + (float(current_stage) * 0.1); var current_scroll_speed = scroll_speed * stage_speed_mult
	_manual_scroll_offset.y += delta * current_scroll_speed; _manual_scroll_offset.x += delta * drift_speed
	var player_parallax = Vector2.ZERO
	if player and is_instance_valid(player):
		player_parallax.x = (player.position.x - 201) * -0.05
		player_parallax.y = (player.position.y - 437) * -0.02
	pb.scroll_offset = (_manual_scroll_offset + player_parallax).round()
	if intro_earth and intro_earth.visible: intro_earth.rotation += delta * 0.01
	for p in _planet_layers_config:
		if p.layer.visible:
			p.layer.motion_offset.y += current_scroll_speed * delta * p.depth
			p.sprite.rotation += delta * p.rot
			if p.layer == mars_layer and mars_moon.visible:
				var orbit_radius = 180.0; var orbit_speed = 1.2
				mars_moon.position.x = mars_sprite.position.x + cos(time_elapsed * orbit_speed) * orbit_radius
				mars_moon.position.y = mars_sprite.position.y + sin(time_elapsed * orbit_speed) * orbit_radius
				mars_moon.rotation += delta * 2.0
	if not game_started: return
	if not boss_spawned and formation_stage == 0 and not _is_transitioning:
		_ambient_meteor_timer -= delta
		if _ambient_meteor_timer <= 0: _spawn_ambient_meteor(); _ambient_meteor_timer = randf_range(1.5, 4.0)
	var min_wait = 1.8
	if timer.wait_time > min_wait: timer.wait_time -= delta * 0.01
	elif timer.wait_time < min_wait: timer.wait_time = min_wait
	if game_started and not boss_spawned and not _is_waiting_for_next_wave and not _is_transitioning:
		var enemy_count = 0
		for child in enemy_container.get_children():
			if not child.has_meta("is_ambient"): enemy_count += 1
		if fleet_controller: enemy_count += fleet_controller.get_child_count()
		
		if _wave_active and enemy_count == 0:
			formation_stage = 0 # Reset stage when cleared
			_start_wave_gap()
	
	if player and is_instance_valid(player) and player._active_boosts.has(BoostManager.BoostType.LASER_UPGRADE):
		hud.show_laser_boost(player._active_boosts[BoostManager.BoostType.LASER_UPGRADE], 20.0)
	else:
		hud.hide_laser_boost()
		
	time_elapsed += delta

func _spawn_ambient_meteor():
	var view_size = get_viewport_rect().size; var pattern_type = randi() % 11
	match pattern_type:
		0: _create_ambient_meteor(Vector2(randf_range(30, view_size.x - 30), -50))
		1: 
			var center_x = randf_range(60, view_size.x - 60)
			for i in range(3): _create_ambient_meteor(Vector2(center_x + randf_range(-50, 50), -50 - randf_range(0, 120)))
		2:
			var start_x = randf_range(50, view_size.x - 50); var side = 1 if start_x < view_size.x/2 else -1
			for i in range(5): _create_ambient_meteor(Vector2(start_x + (i * 30 * side), -50 - (i * 50)))
		3:
			var start_x = randf_range(20, 100); var count = 4; var spacing = (view_size.x - 40) / count
			for i in range(count): _create_ambient_meteor(Vector2(start_x + i * spacing, -50 - randf_range(0, 30)))
		4:
			var center_x = randf_range(100, view_size.x - 100)
			_create_ambient_meteor(Vector2(center_x, -50)); _create_ambient_meteor(Vector2(center_x - 45, -100))
			_create_ambient_meteor(Vector2(center_x + 45, -100)); _create_ambient_meteor(Vector2(center_x - 90, -150))
			_create_ambient_meteor(Vector2(center_x + 90, -150))
		5:
			var start_x = randf_range(20, 60)
			for i in range(5): _create_ambient_meteor(Vector2(start_x + i * 70, -50))
		6:
			var center_x = randf_range(100, view_size.x - 100)
			_create_ambient_meteor(Vector2(center_x, -50)); _create_ambient_meteor(Vector2(center_x - 50, -100))
			_create_ambient_meteor(Vector2(center_x + 50, -100)); _create_ambient_meteor(Vector2(center_x, -150))
		7:
			var start_x = randf_range(100, view_size.x - 100)
			for i in range(4):
				var offset_x = 60 if i % 2 == 0 else -60
				_create_ambient_meteor(Vector2(start_x + offset_x, -50 - i * 80))
		8:
			var start_x = randf_range(100, view_size.x - 100)
			for i in range(6):
				var m = _create_ambient_meteor(Vector2(start_x, -50 - i * 60))
				if m: m.wave_amplitude = 60.0; m.wave_frequency = 2.0; m.phase_offset = -i * 0.8
		9:
			var center_x = randf_range(100, view_size.x - 100); var radius = 80.0
			for i in range(8):
				var angle = i * (TAU / 8.0); _create_ambient_meteor(Vector2(center_x + cos(angle) * radius, -120 + sin(angle) * radius))
		10:
			var center_x = randf_range(100, view_size.x - 100)
			for i in range(-2, 3):
				_create_ambient_meteor(Vector2(center_x + i * 40, -100 + i * 40))
				if i != 0: _create_ambient_meteor(Vector2(center_x + i * 40, -100 - i * 40))

func _create_ambient_meteor(pos: Vector2):
	var m = _spawn_single_meteor(pos)
	if m: m.set_meta("is_ambient", true); m.speed = randf_range(200.0, 400.0); return m
	return null

func _start_wave_gap():
	_is_waiting_for_next_wave = true
	# TIMED BOOSTS NOW HANDLED BY BOOST MANAGER
	await get_tree().create_timer(3.0).timeout
	_is_waiting_for_next_wave = false; _wave_active = false
	if game_started and not boss_spawned and formation_stage == 0 and not _is_transitioning: _on_enemy_spawn_timer_timeout()

func _spawn_boost_at_top(scene):
	if not scene or not game_started: return
	var pu = scene.instantiate(); powerup_container.add_child(pu)
	var view_size = get_viewport_rect().size
	pu.global_position = Vector2(randf_range(80, view_size.x - 80), -60)
	if "speed" in pu: pu.speed = 220.0 

func toggle_pause():
	is_paused = !is_paused; get_tree().paused = is_paused
	if is_paused:
		if death_blur:
			death_blur.visible = true; var tween = create_tween()
			tween.tween_method(func(v): death_blur.material.set_shader_parameter("lod", v), 0.0, 1.5, 0.2).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	else:
		if death_blur:
			var tween = create_tween(); tween.tween_method(func(v): death_blur.material.set_shader_parameter("lod", v), 1.5, 0.0, 0.2).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween.tween_callback(func(): death_blur.visible = false)

func reset_game_state():
	Engine.time_scale = 1.0; get_tree().paused = false; is_paused = false; formation_counter = 0; _is_transitioning = false; seed(42)
	if death_blur: death_blur.visible = false
	if death_flash: death_flash.visible = false

func _warm_up_resources():
	var scenes_to_warm = [
		laser_scene, basic_enemy_scene, diver_enemy_scene, large_enemy_scene, moon_enemy_1, moon_enemy_2,
		meteor_projectile_scene, explosion_scene, explosion_boss_scene, player_scene
	]
	for scene in scenes_to_warm:
		if scene:
			var instance = scene.instantiate(); instance.process_mode = PROCESS_MODE_DISABLED; add_child(instance)
			instance.visible = false; instance.queue_free()

func _on_countdown_started():
	if _launch_tween: _launch_tween.kill()
	_launch_tween = create_tween().set_parallel(true)
	if intro_earth: _launch_tween.tween_property(intro_earth, "position:y", 10000.0, 60.0).set_trans(Tween.TRANS_LINEAR)
	_launch_tween.tween_property(player, "global_position", $PlayerSpawnPos.global_position, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_launch_tween.tween_property(camera, "zoom", Vector2.ONE, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shake_camera(2.0, 4.0)

func _on_restart_requested():
	reset_game_state(); gos.visible = false;
	# Use self. to trigger setters
	self.score = 0
	self.lives = 3
	music_manager.stop_music(); music_manager.set_intensity(0.0); current_stage = Stage.SPACE; time_elapsed = 0.0
	boss_spawned = false; current_formation_index = 0; _last_meteor_patterns.clear()
	moon_layer.visible = false; earth_layer.visible = false; mars_layer.visible = false
	asteroid_belt_layer.visible = false; jupiter_layer.visible = false; saturn_layer.visible = false
	uranus_layer.visible = false; neptune_layer.visible = false; scattered_layer.visible = false
	for enemy in enemy_container.get_children(): enemy.free()
	for laser in laser_container.get_children(): laser.queue_free()
	_laser_pool.clear()
	if player == null or not is_instance_valid(player):
		player = player_scene.instantiate(); add_child(player)
		player.killed.connect(_on_player_killed); player.laser_shot.connect(_on_player_laser_shot)
	if intro_earth: intro_earth.position = Vector2(201, 874); intro_earth.visible = true; intro_earth.modulate.a = 1.0
	player.global_position = Vector2(201, 874); player.set_process(false); player.set_physics_process(false); player.visible = true
	timer.wait_time = 2.5; scroll_speed = 600; camera.zoom = Vector2(1.2, 1.2); start_menu.start_countdown()
	
func _on_start_game():
	game_started = true; hud.visible = true
	if music_manager: music_manager.play_music(); music_manager.set_intensity(0.0)
	timer.start(); player.set_process(true); player.set_physics_process(true)
	_spawn_boost_at_top(laser_boost_scene); get_tree().create_timer(30.0).timeout.connect(_on_repeating_boost_timeout)

func _on_repeating_boost_timeout():
	if not game_started: return
	_spawn_boost_at_top(laser_boost_scene); get_tree().create_timer(30.0).timeout.connect(_on_repeating_boost_timeout)

func _on_player_laser_shot(_scene, pos):
	var laser
	if _laser_pool.size() > 0: laser = _laser_pool.pop_back(); laser.reset(pos)
	else:
		laser = laser_scene.instantiate(); laser.destroyed.connect(_on_laser_destroyed)
		laser_container.add_child(laser); laser.reset(pos)
	if player and player.laser_sound and player.visible: player.laser_sound.play()

func _on_laser_destroyed(laser):
	if not _laser_pool.has(laser): _laser_pool.append(laser)

func check_stage_transition():
	if boss_spawned or _is_transitioning: return
	var next_stage = current_stage
	if score >= 160000: next_stage = Stage.OORT_CLOUD
	elif score >= 140000: next_stage = Stage.KUIPER_BELT
	elif score >= 125000: next_stage = Stage.SCATTERED
	elif score >= 105000: next_stage = Stage.NEPTUNE
	elif score >= 90000: next_stage = Stage.URANUS
	elif score >= 75000: next_stage = Stage.SATURN
	elif score >= 50000: next_stage = Stage.JUPITER
	elif score >= 35000: next_stage = Stage.ASTEROID_BELT
	elif score >= 25000: next_stage = Stage.MARS
	elif score >= 10000: next_stage = Stage.MOON
	if next_stage > current_stage: transition_to_stage(next_stage)

func transition_to_stage(new_stage):
	_is_transitioning = true; current_stage = new_stage; var target_layer = null; var target_sprite = null
	match current_stage:
		Stage.MOON: target_layer = moon_layer; target_sprite = moon_sprite
		Stage.MARS: target_layer = mars_layer; target_sprite = mars_sprite
		Stage.ASTEROID_BELT: target_layer = asteroid_belt_layer; target_sprite = asteroid_belt
		Stage.JUPITER: target_layer = jupiter_layer; target_sprite = jupiter_sprite
		Stage.SATURN: target_layer = saturn_layer; target_sprite = saturn_sprite
		Stage.URANUS: target_layer = uranus_layer; target_sprite = uranus_sprite
		Stage.NEPTUNE: target_layer = neptune_layer; target_sprite = neptune_sprite
		Stage.SCATTERED: target_layer = scattered_layer; target_sprite = scattered_sprite
		Stage.OORT_CLOUD: target_layer = oort_layer; target_sprite = oort_sprite
	if target_layer:
		target_layer.visible = true; target_layer.motion_offset = Vector2(0, -500)
		if target_sprite:
			target_sprite.modulate.a = 0.0; var tween = create_tween(); var final_modulate = 1.0
			if current_stage == Stage.OORT_CLOUD: final_modulate = 0.4
			tween.tween_property(target_sprite, "modulate:a", final_modulate, 1.0); target_sprite.position = Vector2.ZERO
	await get_tree().create_timer(5.0).timeout
	_is_transitioning = false; spawn_boss()
	# if player and is_instance_valid(player): player.upgrade_fire_rate()

func spawn_boss():
	boss_spawned = true; var target_speed = 600.0; var tween = create_tween()
	tween.tween_property(self, "scroll_speed", target_speed, 2.0)
	if music_manager: music_manager.set_intensity(1.0)
	var boss
	match current_stage:
		Stage.MOON: boss = moon_boss_scene.instantiate()
		Stage.MARS: boss = mars_guardian_scene.instantiate()
		Stage.ASTEROID_BELT: boss = meteor_boss_scene.instantiate()
		Stage.JUPITER: boss = jupiter_boss_scene.instantiate()
		Stage.SATURN: boss = saturn_boss_scene.instantiate()
		Stage.URANUS: boss = uranus_boss_scene.instantiate()
		Stage.NEPTUNE: boss = neptune_boss_scene.instantiate()
		Stage.SCATTERED: boss = scattered_boss_scene.instantiate()
		Stage.KUIPER_BELT: boss = meteor_boss_2_scene.instantiate()
		Stage.OORT_CLOUD: boss = oort_boss_scene.instantiate()
	if boss:
		boss.global_position = Vector2(201, -100)
		if "enter_speed" in boss: boss.enter_speed = 150; boss.settle_y = 250
		boss.killed.connect(_on_enemy_killed); boss.hit.connect(_on_enemy_hit)
		enemy_container.add_child(boss); spawn_guardian_escorts(boss, 4)

func spawn_enemy(scene, pos, speed_override = -1.0, points_override = -1, scale_override = Vector2.ZERO, hp_override = -1):
	var view_size = get_viewport_rect().size
	# 1. Determine random off-screen start pos (Top, Left, or Right)
	var start_pos = Vector2.ZERO
	var side = randi() % 3
	match side:
		0: # Top
			start_pos = Vector2(randf_range(0, view_size.x), -100)
		1: # Left
			start_pos = Vector2(-100, randf_range(0, view_size.y * 0.5))
		2: # Right
			start_pos = Vector2(view_size.x + 100, randf_range(0, view_size.y * 0.5))
			
	var e = scene.instantiate()
	e.global_position = start_pos
	
	if speed_override > 0: e.speed = speed_override
	if points_override >= 0: e.points = points_override
	if scale_override != Vector2.ZERO: e.scale = scale_override
	if hp_override > 0: e.hp = hp_override
	
	e.killed.connect(_on_enemy_killed)
	e.hit.connect(_on_enemy_hit)
	enemy_container.add_child(e)
	
	if e.has_method("play_fly_in"):
		e.play_fly_in(pos, randf_range(0.6, 1.0))

func spawn_formation():
	var pattern = current_formation_index % 3
	var center_x = [100, 200, 300, 400, 150, 350, 250].pick_random()
	var scene
	match current_stage:
		Stage.SPACE: scene = basic_enemy_scene
		Stage.MOON: scene = [moon_enemy_1, moon_enemy_2].pick_random()
		Stage.MARS: scene = large_enemy_scene
		Stage.ASTEROID_BELT: scene = [basic_enemy_scene, diver_enemy_scene, large_enemy_scene, moon_enemy_1].pick_random()
		Stage.JUPITER: scene = [moon_enemy_2, large_enemy_scene].pick_random()
		Stage.SATURN: scene = [moon_enemy_1, diver_enemy_scene].pick_random()
		_: scene = large_enemy_scene
		
	match pattern:
		0: 
			for i in range(-1, 2): 
				spawn_enemy(scene, Vector2(center_x + i * 80, 150))
		1: 
			for i in range(-1, 2): 
				spawn_enemy(scene, Vector2(center_x + i * 70, 150 + abs(i) * 50))
		2: 
			for i in range(3): 
				spawn_enemy(scene, Vector2(center_x, 100 + i * 100))
	current_formation_index += 1

func spawn_minions(pos):
	if current_stage != Stage.SPACE and current_stage != Stage.ASTEROID_BELT: 
		formation_stage = 1
		_wave_active = true
		spawn_special_wave()
		return
	for i in range(-1, 2): 
		spawn_enemy(basic_enemy_scene, pos + Vector2(i * 60, abs(i) * 40 + 150))
	timer.start()

func spawn_special_wave():
	var view_size = get_viewport_rect().size
	var count = 6
	var center = Vector2(201, 300)
	var radius = 130.0 if formation_stage == 1 else 180.0
	var scene
	match current_stage:
		Stage.MOON: scene = moon_guardian_orbital_scene
		Stage.MARS: scene = mars_guardian_orbital_scene
		_: scene = jupiter_guardian_orbital_scene
		
	var movement_type = 1 if formation_stage == 1 else 3 
	for i in range(count):
		var target_pos = Vector2((view_size.x / count) * i + (view_size.x / (count * 2)), 250)
		var start_pos = Vector2(target_pos.x, -100)
		
		var e = scene.instantiate()
		e.global_position = start_pos
		e.orbital_center = center
		e.orbit_radius = radius
		e.orbit_angle = i * (TAU / count)
		e.type = movement_type
		e.points = 100
		e.killed.connect(_on_enemy_killed)
		e.hit.connect(_on_enemy_hit)
		enemy_container.add_child(e)
		
		if e.has_method("play_fly_in"):
			e.play_fly_in(target_pos, 1.0)
			
		spawn_guardian_escorts(e, 2)

func spawn_guardian_escorts(target: Node2D, count: int = 3):
	var view_size = get_viewport_rect().size
	for i in range(count):
		var angle = (i * (PI / (count - 1))) - PI/2 if count > 1 else 0
		var pos = target.global_position + Vector2(cos(angle), sin(angle)) * 80.0
		pos.x = clamp(pos.x, 50, view_size.x - 50)
		pos.y = clamp(pos.y, 100, 450)
		
		var side = randi() % 2
		var start_pos = Vector2(-100, pos.y) if side == 0 else Vector2(view_size.x + 100, pos.y)
		
		var s = _spawn_ship(start_pos)
		if s: 
			s.type = BaseEnemy.Type.STATIONARY
			s.hp = 3
			s.modulate = Color(1.2, 0.8, 0.8, 1.0) 
			if s.has_method("play_fly_in"):
				s.play_fly_in(pos, 0.6)

func save_game():
	var save_file = FileAccess.open("user://save.data", FileAccess.READ_WRITE)
	if save_file: save_file.store_32(high_score)

func add_score(amount: int): self.score += amount

func _on_enemy_spawn_timer_timeout() -> void:
	if boss_spawned or is_paused or formation_stage > 0 or _is_transitioning: return
	var pattern_name = WAVE_SEQUENCE[formation_counter % WAVE_SEQUENCE.size()]
	formation_counter += 1
	if pattern_name in ["V", "CIRCLE", "WAVE", "DIAGONAL", "SQUAD", "DIAMOND", "HEXAGON", "SCATTER", "X_PATTERN", "DOUBLE_V", "GRID", "CROSS", "WALL", "SPIRAL"]:
		spawn_meteor_formation(pattern_name)
	else:
		spawn_formation()
	timer.stop()
	_wave_active = true

func spawn_meteor_formation(type: String):
	var view_size = get_viewport_rect().size
	var formation_speed = 180.0 * (1.0 + (float(current_stage) * 0.12))
	match type:
		"CROSS":
			var center = Vector2(201, 250)
			var offsets = [Vector2(0,0), Vector2(0, -100), Vector2(0, 100), Vector2(-100, 0), Vector2(100, 0)]
			for off in offsets:
				var target_pos = center + off
				var s = _spawn_ship(Vector2(target_pos.x, -100))
				if s: 
					s.type = BaseEnemy.Type.STATIONARY; s.hp = 3
					if s.has_method("play_fly_in"): s.play_fly_in(target_pos, 0.7)
		"X_PATTERN":
			var center = Vector2(201, 250)
			var offsets = [Vector2(-120,-120), Vector2(120,-120), Vector2(0,0), Vector2(-120,120), Vector2(120,120)]
			for off in offsets:
				var target_pos = center + off
				var side = randi() % 2
				var start_pos = Vector2(-100, target_pos.y) if side == 0 else Vector2(view_size.x + 100, target_pos.y)
				var s = _spawn_ship(start_pos)
				if s: 
					s.type = BaseEnemy.Type.STATIONARY; s.hp = 3
					if s.has_method("play_fly_in"): s.play_fly_in(target_pos, 0.8)
		"DOUBLE_V":
			var center_x = 201
			for i in range(3):
				var target1 = Vector2(center_x + (i-1)*80, 150 + abs(i-1)*60)
				var target2 = Vector2(center_x + (i-1)*80, 350 + abs(i-1)*60)
				var s1 = _spawn_ship(Vector2(target1.x, -100))
				var s2 = _spawn_ship(Vector2(target2.x, -100))
				s1.hp = 3; s2.hp = 3
				if s1.has_method("play_fly_in"): s1.play_fly_in(target1, 0.9)
				if s2.has_method("play_fly_in"): s2.play_fly_in(target2, 1.1)
		"GRID":
			for x in range(3):
				for y in range(3):
					var target_pos = Vector2(100 + x*100, 150 + y*80)
					var side = randi() % 2
					var start_pos = Vector2(-100, target_pos.y) if side == 0 else Vector2(view_size.x + 100, target_pos.y)
					var s = _spawn_ship(start_pos)
					if s: 
						s.type = BaseEnemy.Type.STATIONARY; s.hp = 3
						if s.has_method("play_fly_in"): s.play_fly_in(target_pos, 0.6 + (x+y)*0.1)
		"WALL":
			for i in range(5):
				var target_pos = Vector2(60 + i*70, 150)
				var s = _spawn_ship(Vector2(target_pos.x, -100))
				if s: 
					s.type = BaseEnemy.Type.STATIONARY; s.hp = 3
					if s.has_method("play_fly_in"): s.play_fly_in(target_pos, 0.5 + i*0.1)
		"DIAMOND":
			var center = Vector2(201, -100)
			for i in range(4):
				var m = _spawn_single_meteor(center, formation_speed)
				if m: m.movement_strategy = DiamondStrategy.new(i)
		"HEXAGON":
			var center = Vector2(201, 240)
			for i in range(6):
				var angle = i * (TAU / 6.0)
				var target_pos = center + Vector2(cos(angle), sin(angle)) * 140.0
				var start_pos = Vector2(target_pos.x > view_size.x/2 if view_size.x + 100 else -100, target_pos.y)
				var s = _spawn_ship(start_pos)
				if s: 
					s.type = BaseEnemy.Type.STATIONARY; s.hp = 3
					if s.has_method("play_fly_in"): s.play_fly_in(target_pos, 0.8)
		"SCATTER":
			for i in range(6):
				var target_pos = Vector2(randf_range(60, view_size.x - 60), randf_range(80, 350))
				var side = randi() % 3
				var start_pos = Vector2.ZERO
				if side == 0: start_pos = Vector2(target_pos.x, -100)
				elif side == 1: start_pos = Vector2(-100, target_pos.y)
				else: start_pos = Vector2(view_size.x + 100, target_pos.y)
				var s = _spawn_ship(start_pos)
				if s: 
					s.type = BaseEnemy.Type.STATIONARY; s.hp = 3
					if s.has_method("play_fly_in"): s.play_fly_in(target_pos, randf_range(0.5, 1.0))
		"SQUAD":
			var center_x = randf_range(100, view_size.x - 100)
			for i in range(3):
				var target_pos = Vector2(center_x + (i-1)*90, 150 + i*40)
				var s = _spawn_ship(Vector2(target_pos.x, -100))
				if s: 
					s.type = BaseEnemy.Type.STATIONARY; s.hp = 3
					if s.has_method("play_fly_in"): s.play_fly_in(target_pos, 0.7)
		"V":
			var center_x = randf_range(120, view_size.x - 120)
			for i in range(5):
				var target_pos = Vector2(center_x + (i-2)*75, 120 + abs(i-2)*60)
				var s = _spawn_ship(Vector2(target_pos.x, -100))
				if s: 
					s.type = BaseEnemy.Type.STATIONARY; s.hp = 3
					if s.has_method("play_fly_in"): s.play_fly_in(target_pos, 0.6 + abs(i-2)*0.1)
		"CIRCLE":
			var center = Vector2(201, -180)
			for i in range(12):
				var angle = i * (TAU / 12); _spawn_single_meteor(center + Vector2(cos(angle), sin(angle)) * 120.0, formation_speed)
		"WAVE":
			var start_x = randf_range(80, view_size.x - 80)
			for i in range(10):
				var m = _spawn_single_meteor(Vector2(start_x, -150 - i * 60.0), formation_speed)
				if m: m.wave_amplitude = 80.0; m.wave_frequency = 3.0; m.phase_offset = -i * 0.5
		"DIAGONAL":
			var is_left = randf() < 0.5; var start_x = -80 if is_left else view_size.x + 80
			var dir = Vector2(1.2, 1).normalized() if is_left else Vector2(-1.2, 1).normalized()
			for i in range(12):
				var m = _spawn_single_meteor(Vector2(start_x - dir.x * i * 60.0, -120 - i * 60.0), formation_speed + 40)
				if m: m.direction = dir; m.rotation_speed = 4.0 * (1 if is_left else -1)
		"SPIRAL":
			var center_x = 201
			for i in range(15):
				var angle = i * 0.5; _spawn_single_meteor(Vector2(center_x + cos(angle) * 130.0, -120 - i * 45.0), formation_speed)

func _spawn_ship(pos: Vector2, speed_override: float = 0.0) -> BaseEnemy:
	if !enemy_ship_scene: return null
	var s = enemy_ship_scene.instantiate()
	s.global_position = pos
	if speed_override > 0: s.speed = speed_override
	s.killed.connect(_on_enemy_killed); s.hit.connect(_on_enemy_hit); enemy_container.add_child(s); return s

func _spawn_single_meteor(pos: Vector2, speed_override: float = 0.0) -> MeteorProjectile:
	if !meteor_projectile_scene: return null
	var m = meteor_projectile_scene.instantiate(); m.global_position = pos; m.scale = Vector2.ZERO
	var tween = create_tween(); tween.tween_property(m, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	m.set_meta("spawn_x", pos.x)
	if speed_override > 0: m.speed = speed_override
	m.movement_strategy = SimpleMovement.new(); m.killed.connect(_on_enemy_killed); enemy_container.add_child(m); return m

func shake_camera(intensity: float, duration: float):
	if !camera: return
	var shake_tween = create_tween(); shake_tween.tween_method(func(v): 
		var damp = v / intensity
		camera.offset = Vector2(randf_range(-v, v), randf_range(-v, v)) * damp, intensity, 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	shake_tween.tween_callback(func(): camera.offset = Vector2.ZERO)

func _on_enemy_killed(points, pos):
	var explosion
	if points >= 500: explosion = explosion_boss_scene.instantiate(); explosion.scale = Vector2(0.7, 0.7); shake_camera(10.0, 0.5)
	else: explosion = explosion_scene.instantiate(); shake_camera(2.0, 0.1)
	explosion.global_position = pos; add_child(explosion); explode_sound.play()
	
	# Use self. to trigger setter
	self.score += points
	
	# RANDOM ENEMY DROPS REMOVED: BoostManager handles all timered power-ups.
	# We only keep Coin drops from enemies for score balancing.
	if coin_boost_scene and randf() < 0.15: 
		var pu = coin_boost_scene.instantiate()
		powerup_container.add_child(pu); pu.global_position = pos

	if points >= 500: 
		boss_spawned = false; var normal_speed = 600.0; var tween = create_tween()
		tween.tween_property(self, "scroll_speed", normal_speed, 2.0); spawn_minions(pos)

func _on_enemy_hit(): hit_sound.play()

func _on_player_killed():
	var last_player_pos = Vector2.ZERO
	if is_instance_valid(player): last_player_pos = player.global_position
	# Use self. to trigger setter
	self.lives -= 1
	Engine.time_scale = 0.05
	if death_flash:
		death_flash.visible = true; death_flash.color.a = 0.8; var flash_tween = create_tween()
		flash_tween.tween_property(death_flash, "color:a", 0.0, 0.1); flash_tween.tween_callback(func(): death_flash.visible = false)
	shake_camera(8.0, 0.2)
	if death_blur:
		death_blur.visible = true; var blur_tween = create_tween()
		blur_tween.tween_method(func(v): death_blur.material.set_shader_parameter("lod", v), 0.0, 2.0, 0.2)
	await get_tree().create_timer(0.15, true, false, true).timeout
	Engine.time_scale = 1.0
	if lives > 0:
		var explosion = explosion_scene.instantiate(); explosion.global_position = last_player_pos
		add_child(explosion); explode_sound.play(); await get_tree().create_timer(0.8).timeout
		if death_blur:
			var blur_out = create_tween(); blur_out.tween_method(func(v): death_blur.material.set_shader_parameter("lod", v), 2.0, 0.0, 0.3)
			blur_out.tween_callback(func(): death_blur.visible = false)
		player = player_scene.instantiate(); add_child(player)
		player.killed.connect(_on_player_killed); player.laser_shot.connect(_on_player_laser_shot)
		player.global_position = $PlayerSpawnPos.global_position
		player.make_invincible(3.0)
	else:
		game_started = false; timer.stop()
		if music_manager: music_manager.stop_music(); music_manager.set_intensity(0.0)
		if game_over_sound: game_over_sound.play()
		await get_tree().create_timer(1.5).timeout
		if gos: gos.set_score(score); gos.high_set_score(high_score); gos.show_screen()
		save_game()
