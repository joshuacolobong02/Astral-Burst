extends BaseEnemy

# Orbit properties
var orbit_center_node: Node2D
var orbit_angle: float = 0.0
var orbit_radius: float = 180.0
var orbit_speed: float = 1.5

# Shooting properties
var projectile_scene = preload("res://scene/meteor_projectile.tscn")
var shoot_interval_min: float = 2.5 
var shoot_interval_max: float = 4.5

var _attack_pattern_index: int = 0
var _is_dying = false

var independent = false
var direction = Vector2.DOWN
var explosion_scene = preload("res://scene/explode_animate.tscn")

func _ready():
	# Don't show HP label for minions to reduce clutter
	if hp_label:
		hp_label.visible = false
	reset_shoot_timer()
	
	# Determine initial angle based on position if parent is the center
	orbit_angle = position.angle()
	orbit_radius = position.length()
	
	super._ready()

func reset_pool_state():
	super.reset_pool_state()
	_is_dying = false
	_attack_pattern_index = 0
	reset_shoot_timer()

func _physics_process(delta):
	if _is_dying: return
	
	if independent:
		# Linear movement (Projectile mode)
		global_position += direction * speed * delta
		rotation += 5.0 * delta # Automatic spin
	else:
		# Orbit logic
		orbit_angle += orbit_speed * delta
		position = Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
		
		# Shooting logic (Only when orbiting)
		ai_shoot_timer -= delta
		if ai_shoot_timer <= 0:
			shoot()
			reset_shoot_timer()

func reset_shoot_timer():
	ai_shoot_timer = randf_range(shoot_interval_min, shoot_interval_max)

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
		explosion.scale = Vector2(0.5, 0.5)
		if explosion.has_method("reset_pool_state"):
			explosion.reset_pool_state()
			
	super.die()

func shoot():
	if _is_dying: return
	
	var pattern = _attack_pattern_index % 3
	_attack_pattern_index += 1
	
	match pattern:
		0: # Fan Spread
			var angles = [-25, -12, 0, 12, 25]
			for angle in angles:
				_emit_meteor(angle)
		1: # Forward Burst (Vertical stack)
			for i in range(4):
				_emit_meteor(0, i * 40.0) 
		2: # Circular Pulse
			var count = 6
			for i in range(count):
				var angle = (i * (360.0 / count)) - 90.0
				_emit_meteor(angle)

func _emit_meteor(angle_offset: float, pos_offset_y: float = 0.0):
	var rad = deg_to_rad(angle_offset + 90.0)
	var dir = Vector2(cos(rad), sin(rad))
	var spawn_pos = global_position + Vector2(0, 30 + pos_offset_y)
	
	meteor_shot.emit(spawn_pos, dir, Vector2.ONE)
