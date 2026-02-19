extends BaseEnemy

var independent = false

# Orbit properties
var initial_pos: Vector2
var orbit_angle: float = 0.0
var orbit_radius: float = 0.0
var orbit_speed: float = 1.0

var explosion_scene = preload("res://scene/explode_animate.tscn")
var projectile_scene = preload("res://scene/meteor_projectile.tscn")
var red_meteor_tex = preload("res://asset/PNG/Meteors/MeteorRed3.png")

var time_passed = 0.0
var target_scale = Vector2(1.0, 1.0)
var _is_dying = false

# Phase Logic
var max_hp: int = 10
var is_desperate = false

# Shooting properties
var shoot_timer: float = 0.0
var shoot_interval_min: float = 2.0
var shoot_interval_max: float = 5.0

func _ready():
	super._ready()
	is_spawning = true 
	initial_pos = position 
	orbit_radius = position.length()
	orbit_angle = position.angle()
	time_passed = randf() * TAU
	
	max_hp = hp if hp > 0 else 10
	
	target_scale = scale
	modulate.a = 0.0
	scale = Vector2(0.01, 0.01)
	reset_shoot_timer()

func die():
	if _is_dying: return
	_is_dying = true
	
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
		explosion.scale = Vector2(0.8, 0.8)
		if explosion.has_method("reset_pool_state"):
			explosion.reset_pool_state()
		
		if game.has_method("shake_camera"):
			game.shake_camera(3.0, 0.15)
			
	super.die()

func _physics_process(delta):
	if _is_dying: return
	
	# Difficulty Check
	if !is_desperate and hp <= (max_hp / 2):
		_enter_desperation_phase()
	
	var hit_running = current_hit_tween != null and current_hit_tween.is_running()
	
	if is_spawning:
		modulate.a = move_toward(modulate.a, 1.0, delta * 2.0)
		if !hit_running:
			scale = scale.move_toward(target_scale, delta * 2.0)
		if modulate.a >= 1.0 and scale.is_equal_approx(target_scale):
			is_spawning = false
		return

	time_passed += delta
	var speed_mod = 2.0 if is_desperate else 1.0

	if independent:
		# DYNAMIC SWAYING ROAMING (Instead of just falling)
		var hover_x = sin(time_passed * 2.5 * speed_mod) * 60.0
		var hover_y = cos(time_passed * 1.5 * speed_mod) * 30.0
		global_position.y += speed * delta * 0.5 # Slower fall, more sway
		global_position.x += hover_x * delta * 5.0
		rotation += (2.0 * speed_mod) * delta
	else:
		# Orbit logic
		orbit_angle += orbit_speed * delta * speed_mod
		position = Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
		rotation += 1.0 * delta * speed_mod
		
	if is_desperate:
		modulate = Color(1.5, 0.5, 0.5, 1.0).lerp(Color.WHITE, (sin(time_passed * 10.0) + 1.0) * 0.5)
		
	# Shooting logic
	shoot_timer -= delta
	if shoot_timer <= 0:
		shoot()
		reset_shoot_timer()

func _enter_desperation_phase():
	is_desperate = true
	shoot_interval_min *= 0.5
	shoot_interval_max *= 0.5

func reset_shoot_timer():
	shoot_timer = randf_range(shoot_interval_min, shoot_interval_max)

func shoot():
	if _is_dying: return
	
	# Fan pattern increases in desperation
	var angles = [-15, 0, 15]
	if is_desperate: angles = [-30, -15, 0, 15, 30]
	
	for angle in angles:
		var rad = deg_to_rad(angle + 90.0)
		var dir = Vector2(cos(rad), sin(rad))
		meteor_shot.emit(global_position, dir, Vector2.ONE)
