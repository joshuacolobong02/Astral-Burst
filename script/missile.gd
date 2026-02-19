extends Area2D

@export var speed := 500.0
@export var turn_speed := 5.0
@export var damage := 5
@export var lifetime := 4.0

var target: Node2D = null
var velocity := Vector2.ZERO
var explosion_scene = preload("res://scene/explode_animate.tscn")
var _is_exploding := false
var _lifetime_timer: SceneTreeTimer

func _ready():
	reset_pool_state()

func reset_pool_state():
	_is_exploding = false
	target = null
	velocity = Vector2.UP.rotated(rotation) * speed
	show()
	set_physics_process(true)
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	
	if _lifetime_timer:
		_lifetime_timer.timeout.disconnect(_on_lifetime_timeout)
	
	_lifetime_timer = get_tree().create_timer(lifetime)
	_lifetime_timer.timeout.connect(_on_lifetime_timeout)

func _on_lifetime_timeout():
	if not _is_exploding:
		_destroy()

func _physics_process(delta):
	if _is_exploding: return
	
	if !is_instance_valid(target) or target.is_queued_for_deletion():
		target = _find_nearest_enemy()
	
	if is_instance_valid(target):
		var target_dir = (target.global_position - global_position).normalized()
		var current_dir = velocity.normalized()
		var new_dir = current_dir.lerp(target_dir, turn_speed * delta).normalized()
		velocity = new_dir * speed
		rotation = velocity.angle() + PI/2
	
	global_position += velocity * delta

func _find_nearest_enemy() -> Node2D:
	var candidates: Array[Node2D] = []
	# Enemies: boss, guardian groups + BaseEnemy + MeteorProjectile
	for group in ["enemy", "boss", "guardian"]:
		for n in get_tree().get_nodes_in_group(group):
			if n is Node2D and (n is BaseEnemy or n is MeteorProjectile or n.has_method("take_damage")):
				if is_instance_valid(n) and !n.is_queued_for_deletion():
					candidates.append(n)
	# Fallback: EnemyContainer children
	var container = get_tree().current_scene.get_node_or_null("EnemyContainer")
	if container:
		for c in container.get_children():
			if c is Node2D and c.has_method("take_damage"):
				if is_instance_valid(c) and !c.is_queued_for_deletion() and c not in candidates:
					candidates.append(c)
	var nearest: Node2D = null
	var min_dist := INF
	for e in candidates:
		var d = global_position.distance_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e
	return nearest

func _on_body_entered(body):
	if _is_exploding: return
	if body.is_in_group("powerup"): return
	if body is BaseEnemy or body is MeteorProjectile or body.has_method("take_damage"):
		_explode(body)

func _on_area_entered(area):
	if _is_exploding: return
	if area.is_in_group("powerup"): return
	if area is BaseEnemy or area is MeteorProjectile or area.has_method("take_damage"):
		_explode(area)

func _explode(victim):
	if _is_exploding: return
	_is_exploding = true
	
	if victim.has_method("take_damage"):
		victim.take_damage(damage)
	
	var game = get_tree().current_scene
	if explosion_scene:
		var exp: Node
		if game and "pool_manager" in game and is_instance_valid(game.pool_manager):
			exp = game.pool_manager.get_node_from_pool(explosion_scene)
		else:
			exp = explosion_scene.instantiate()
			
		if not exp.get_parent():
			game.add_child.call_deferred(exp)
		exp.global_position = global_position
		if exp.has_method("reset_pool_state"):
			exp.reset_pool_state()
	
	_destroy()

func _destroy():
	hide()
	set_physics_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	var game = get_tree().current_scene
	if game and "pool_manager" in game and is_instance_valid(game.pool_manager):
		game.pool_manager.return_to_pool(self, "res://scene/missile.tscn")
	else:
		queue_free()
