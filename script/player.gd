class_name Player extends CharacterBody2D

signal laser_shot(laser_scene: PackedScene, position: Vector2, speed_mult: float, direction: Vector2)
signal killed
signal boost_collected(type: BoostManager.BoostType)
signal boost_expired(type: BoostManager.BoostType)

@onready var player_spawn_pos = $"../PlayerSpawnPos"
@onready var muzzle = $Muzzle
@onready var laser_sound = $"../SFX/LaserSound"
@onready var sprite = $Sprite2D

@export var SPEED = 400.0
@export var ACCELERATION = 2500.0
@export var FRICTION = 2000.0
@export var fire_rate = 0.22 # Base fire rate

var laser_scene = preload("res://scene/laser.tscn")
var missile_scene = preload("res://scene/missile.tscn")

# Effect States
var _active_boosts: Dictionary = {}
var _laser_speed_mult = 1.0
var touch_active := false
var is_dying := false

var has_shield := false
var shield_sprite: Sprite2D

@export var is_invincible = false
@export var god_mode = false
var _invincible_timer := 0.0
var _flash_timer := 0.0

var missile_charges := 0  
var _wing_missile_left: Sprite2D
var _wing_missile_right: Sprite2D

var _last_drag_relative := Vector2.ZERO
const TOUCH_DELTA_CLAMP := 800.0  

var _shoot_cooldown := 0.0

func _ready():
	add_to_group("player")
	if player_spawn_pos:
		global_position = player_spawn_pos.global_position
	
	_setup_shield_visual()
	_setup_wing_missiles()

func _setup_wing_missiles():
	var missile_tex = preload("res://asset/PNG/Boost/Missile.png")
	_wing_missile_left = Sprite2D.new()
	_wing_missile_left.texture = missile_tex
	_wing_missile_left.scale = Vector2(0.08, 0.08)
	_wing_missile_left.position = Vector2(-45, 25)
	_wing_missile_left.visible = false
	add_child(_wing_missile_left)
	_wing_missile_right = Sprite2D.new()
	_wing_missile_right.texture = missile_tex
	_wing_missile_right.scale = Vector2(0.08, 0.08)
	_wing_missile_right.position = Vector2(45, 25)
	_wing_missile_right.visible = false
	add_child(_wing_missile_right)

func _update_wing_missiles():
	var show = missile_charges > 0
	if _wing_missile_left: _wing_missile_left.visible = show
	if _wing_missile_right: _wing_missile_right.visible = show

func _setup_shield_visual():
	shield_sprite = Sprite2D.new()
	shield_sprite.texture = preload("res://asset/PNG/Effects/shield3.png")
	shield_sprite.scale = Vector2(1.2, 1.2)
	shield_sprite.modulate = Color(0.5, 0.8, 1.0, 0.0)
	add_child(shield_sprite)
	var shield_tween = create_tween().set_loops()
	shield_tween.tween_property(shield_sprite, "rotation", TAU, 4.0).from(0.0)

func apply_boost(type: BoostManager.BoostType, duration: float = 20.0):
	if type == BoostManager.BoostType.MISSILE:
		missile_charges = mini(missile_charges + 2, 2)
		_update_wing_missiles()
		boost_collected.emit(type)
		return
	if _active_boosts.has(type):
		_active_boosts[type] = duration
		return
	_active_boosts[type] = duration
	boost_collected.emit(type)
	match type:
		BoostManager.BoostType.LASER_UPGRADE:
			sprite.modulate = Color(1.5, 1.5, 2.0)
		BoostManager.BoostType.LASER_SPEED:
			_laser_speed_mult = 2.5
		BoostManager.BoostType.SHIELD:
			has_shield = true
			var t = create_tween()
			t.tween_property(shield_sprite, "modulate:a", 0.8, 0.3)
			t.parallel().tween_property(shield_sprite, "scale", Vector2(1.2, 1.2), 0.3).from(Vector2.ZERO)

func _remove_boost(type: BoostManager.BoostType):
	if !_active_boosts.has(type): return
	_active_boosts.erase(type)
	boost_expired.emit(type)
	
	match type:
		BoostManager.BoostType.LASER_UPGRADE:
			sprite.modulate = Color.WHITE
		BoostManager.BoostType.LASER_SPEED:
			_laser_speed_mult = 1.0
		BoostManager.BoostType.SHIELD:
			has_shield = false
			var t = create_tween()
			t.tween_property(shield_sprite, "modulate:a", 0.0, 0.3)

func has_laser_boost_active() -> bool:
	return _active_boosts.has(BoostManager.BoostType.LASER_UPGRADE)

func get_laser_boost_remaining() -> float:
	var target_type = BoostManager.BoostType.LASER_UPGRADE
	if _active_boosts.has(BoostManager.BoostType.MISSILE):
		target_type = BoostManager.BoostType.MISSILE
	
	if !_active_boosts.has(target_type):
		return 0.0
	return _active_boosts[target_type]

func get_missile_charges() -> int:
	return missile_charges

func make_invincible(duration: float):
	is_invincible = true
	_invincible_timer = duration
	_flash_timer = 0.0

func _process(delta):
	if not visible: return
	
	if is_invincible:
		_invincible_timer -= delta
		_flash_timer -= delta
		if _flash_timer <= 0:
			sprite.visible = !sprite.visible
			_flash_timer = 0.08
		if _invincible_timer <= 0:
			is_invincible = false
			sprite.visible = true
	
	for type in _active_boosts.keys():
		_active_boosts[type] -= delta
		if _active_boosts[type] <= 0:
			_remove_boost(type)
	
func shoot():
	if is_dying or !visible: return
	
	var base_dir = Vector2.UP.rotated(rotation)
	var spawn_pos = muzzle.global_position
	
	# Center laser
	laser_shot.emit(laser_scene, spawn_pos, _laser_speed_mult, base_dir)
	
	if has_laser_boost_active():
		# Five-way spread
		var angles = [-15, 15, -30, 30]
		var offsets = [Vector2(-35, 5), Vector2(35, 5), Vector2(-70, 20), Vector2(70, 20)]
		for i in range(angles.size()):
			var dir = base_dir.rotated(deg_to_rad(angles[i]))
			var pos = spawn_pos + offsets[i].rotated(rotation)
			laser_shot.emit(laser_scene, pos, _laser_speed_mult, dir)
	else:
		# Standard three-way spread
		var angles = [-12, 12]
		var offsets = [Vector2(-28, 12), Vector2(28, 12)]
		for i in range(angles.size()):
			var dir = base_dir.rotated(deg_to_rad(angles[i]))
			var pos = spawn_pos + offsets[i].rotated(rotation)
			laser_shot.emit(laser_scene, pos, _laser_speed_mult, dir)
		
	if laser_sound:
		var game = get_tree().current_scene
		if game and "sfx_manager" in game and is_instance_valid(game.sfx_manager):
			game.sfx_manager.play_sfx(laser_sound.stream, -32.0)
		elif !laser_sound.playing:
			laser_sound.play()

func shoot_missiles():
	if missile_charges <= 0: return
	missile_charges -= 1
	_update_wing_missiles()
	var offsets = [Vector2(-45, 25), Vector2(45, 25)]
	var game = get_tree().current_scene
	for off in offsets:
		var m: Node
		if game and "pool_manager" in game and is_instance_valid(game.pool_manager):
			m = game.pool_manager.get_node_from_pool(missile_scene)
		else:
			m = missile_scene.instantiate()
			
		m.global_position = global_position + off.rotated(rotation)
		if not m.get_parent():
			game.add_child.call_deferred(m)
		
		# Call reset_pool_state deferred so it happens after the node is in the tree
		if m.has_method("reset_pool_state"):
			m.call_deferred("reset_pool_state")

func take_hit():
	if is_invincible or is_dying or god_mode: return
	if has_shield:
		_remove_boost(BoostManager.BoostType.SHIELD)
		return
	die()

func _physics_process(delta):
	if is_dying: return
	
	# Movement Logic
	if touch_active:
		var drag_move = _last_drag_relative
		_last_drag_relative = Vector2.ZERO
		if delta > 0:
			velocity = (drag_move / delta).limit_length(TOUCH_DELTA_CLAMP)
		global_position += drag_move
	else:
		var direction = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")).normalized()
		if direction != Vector2.ZERO:
			velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		move_and_slide()
	
	rotation = lerp_angle(rotation, deg_to_rad(clamp(velocity.x / SPEED, -1.5, 1.5) * 20.0), delta * 10.0)
	
	# Clamp to design resolution 402x874 with margin
	var margin = 20.0
	global_position.x = clamp(global_position.x, margin, 402.0 - margin)
	global_position.y = clamp(global_position.y, margin, 874.0 - margin)
	
	# Physics-synced Shooting Cooldown with precision accumulation
	_shoot_cooldown -= delta
	if _shoot_cooldown <= 0:
		shoot()
		var interval = fire_rate
		if has_laser_boost_active():
			interval *= 0.4
		
		if _shoot_cooldown < -interval: # Handle initial state or huge hitch
			_shoot_cooldown = interval
		else:
			_shoot_cooldown += interval

func die():
	if is_dying or god_mode: return
	_active_boosts.clear()
	_laser_speed_mult = 1.0
	has_shield = false
	missile_charges = 0
	_update_wing_missiles()
	if shield_sprite:
		shield_sprite.modulate.a = 0.0
	
	is_dying = true
	killed.emit()
	queue_free()

func _input(event):
	if event is InputEventScreenTouch:
		touch_active = event.pressed
		if not touch_active: _last_drag_relative = Vector2.ZERO
	elif event is InputEventScreenDrag and touch_active:
		_last_drag_relative += event.relative
	if event.is_action_pressed("fire_missile") and missile_charges > 0:
		shoot_missiles()

func upgrade_fire_rate(): 
	fire_rate = max(0.1, fire_rate - 0.05)
