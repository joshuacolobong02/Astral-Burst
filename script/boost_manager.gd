extends Node2D

## Central authority for boost spawning and timing logic.
class_name BoostManager

enum BoostType { LASER_UPGRADE, LASER_SPEED, SHIELD }

@export var laser_boost_scene: PackedScene
@export var speed_boost_scene: PackedScene
@export var shield_boost_scene: PackedScene

@onready var spawn_timer = Timer.new()
@onready var cooldown_timer = Timer.new()

var player: Player = null
var powerup_container: Node2D = null

func _ready():
	# Configure Timers
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_finished)
	add_child(cooldown_timer)
	
	# Initial delay after launch
	spawn_timer.start(3.0)

func setup(p: Player, container: Node2D):
	player = p
	powerup_container = container
	if player:
		player.boost_collected.connect(_on_player_boost_collected)
		player.boost_expired.connect(_on_player_boost_expired)

func _on_spawn_timer_timeout():
	spawn_boosts()

func spawn_boost():
	var types = [BoostType.LASER_UPGRADE, BoostType.LASER_SPEED, BoostType.SHIELD]
	return types.pick_random()

func spawn_boosts():
	if !player or !is_instance_valid(player) or !powerup_container: return
	
	var is_boss_active = _is_boss_present()
	var count = 2 if is_boss_active else 1
	var view_size = get_viewport_rect().size
	
	# Used to ensure different types for boss spawns
	var used_types = []
	
	for i in range(count):
		var type = spawn_boost()
		if i > 0 and type in used_types: # Try to get a different one for the second drop
			type = spawn_boost()
			
		used_types.append(type)
		_instantiate_boost(type, i, count, view_size)

func _instantiate_boost(type: BoostType, index: int, total: int, view_size: Vector2):
	var scene = laser_boost_scene
	match type:
		BoostType.LASER_SPEED: scene = speed_boost_scene
		BoostType.SHIELD: scene = shield_boost_scene
	
	if !scene: return
	
	var inst = scene.instantiate()
	powerup_container.add_child(inst)
	inst.z_index = 150
	
	# Split X positions if spawning multiple
	var x_seg = view_size.x / (total + 1)
	var target_x = x_seg * (index + 1)
	inst.global_position = Vector2(target_x, -60)

func _is_boss_present() -> bool:
	# Checks for any node in the 'boss' or 'guardian' groups
	return get_tree().get_nodes_in_group("boss").size() > 0 or get_tree().get_nodes_in_group("guardian").size() > 0

func _on_player_boost_collected(_type):
	# Stop spawn logic while a boost is being used
	spawn_timer.stop()

func _on_player_boost_expired(_type):
	# Start the 30s cooldown before next drop
	cooldown_timer.start(30.0)

func _on_cooldown_finished():
	spawn_boosts()
