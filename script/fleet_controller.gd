extends Node2D

@export var rows := 4
@export var cols := 6
@export var spacing := Vector2(60, 50)
@export var base_speed := 150.0
@export var drop_distance := 30.0

var direction := 1.0
var current_speed := 150.0
var dive_timer := 0.0
var total_initial_meteors := 0

@onready var enemy_container = $"../EnemyContainer"
@onready var player = $"../Player"

func setup_grid(r: int, c: int, s: Vector2, speed: float):
	rows = r
	cols = c
	spacing = s
	base_speed = speed * 1.2 # Boost speed slightly for difficulty
	
	# Clear existing
	for child in get_children():
		child.queue_free()
		
	var view_width = 402
	var start_x = (view_width - (cols * spacing.x)) / 2
	
	for row in rows:
		for col in cols:
			var slot_pos = Vector2(start_x + (col * spacing.x), 100 + (row * spacing.y))
			spawn_unit(slot_pos)
	
	total_initial_meteors = get_child_count()
	current_speed = base_speed

func spawn_unit(slot_pos: Vector2):
	# Dedicated Ship Fleet (No meteors)
	var unit = preload("res://scene/enemy_ship.tscn").instantiate()
		
	add_child(unit)
	unit.position = slot_pos
	
	# Use FleetMovement strategy
	unit.movement_strategy = FleetMovement.new()
	
	var game = get_tree().current_scene
	if unit.has_signal("killed") and game.has_method("_on_enemy_killed"):
		unit.killed.connect(game._on_enemy_killed)

func _physics_process(delta: float):
	if get_child_count() == 0: return

	# 1. Update Speed based on count (Classic arcade scaling)
	var count = get_child_count()
	var remaining_perc = float(count) / max(1, total_initial_meteors)
	current_speed = base_speed * (2.8 - remaining_perc) # More aggressive scaling

	# 2. Horizontal Movement
	position.x += direction * current_speed * delta
	
	# 3. Edge Detection
	if _check_bounds():
		# Only flip if moving towards the edge
		if (direction > 0 and _is_at_right_edge()) or (direction < 0 and _is_at_left_edge()):
			direction *= -1
			# Smooth vertical drop
			var drop_tween = create_tween()
			drop_tween.tween_property(self, "position:y", position.y + drop_distance, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			
			# Tighten formation slightly on drop
			spacing *= 0.98 

	# 4. Random Dive Logic
	dive_timer += delta
	# Faster dives: 1.0 to 3.5s interval
	if dive_timer > randf_range(1.0, 3.5):
		trigger_random_dive()
		dive_timer = 0.0

func _check_bounds() -> bool:
	return _is_at_left_edge() or _is_at_right_edge()

func _is_at_left_edge() -> bool:
	var left_limit = 20 - position.x
	for m in get_children():
		if m.position.x < left_limit:
			return true
	return false

func _is_at_right_edge() -> bool:
	var right_limit = 382 - position.x
	for m in get_children():
		if m.position.x > right_limit:
			return true
	return false

func trigger_random_dive():
	var children = get_children()
	if children.is_empty(): return
	
	var unit = children.pick_random()
	var global_start = unit.global_position
	
	# Detach from fleet
	remove_child(unit)
	enemy_container.add_child(unit)
	unit.global_position = global_start
	
	# Switch to Seeker/Dive logic
	if unit is BaseEnemy:
		unit.type = BaseEnemy.Type.SEEKER
		unit.speed *= 1.8
	else:
		# Meteors use DiveMovement strategy
		var strategy = DiveMovement.new()
		if is_instance_valid(player):
			strategy.target_player = player
		strategy.velocity = Vector2(0, 250)
		unit.movement_strategy = strategy
