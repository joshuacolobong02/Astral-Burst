class_name Player extends CharacterBody2D

signal laser_shot(laser_scene, location)
signal killed
signal boost_collected(type: BoostManager.BoostType)
signal boost_expired(type: BoostManager.BoostType)

@onready var player_spawn_pos = $"../PlayerSpawnPos"
@onready var muzzle = $Muzzle 
@onready var laser_container = $"../LaserContainer"
@onready var laser_sound = $"../SFX/LaserSound"
@onready var sprite = $Sprite2D

@export var SPEED = 400.0
@export var ACCELERATION = 2500.0
@export var FRICTION = 2000.0
@export var fire_shoot = 0.25

var laser_scene = preload("res://scene/laser.tscn")

# Effect States
var _active_boosts: Dictionary = {}
var _laser_speed_mult = 1.0
var _fire_timer := 0.0
var touch_active := false
var is_dying := false

var has_shield := false
var shield_sprite: Sprite2D

@export var is_invincible = false
@export var god_mode = false
var _invincible_timer := 0.0
var _flash_timer := 0.0

var _last_drag_relative := Vector2.ZERO

func _ready():
	add_to_group("player")
	if player_spawn_pos:
		global_position = player_spawn_pos.global_position
	
	_setup_shield_visual()

func _setup_shield_visual():
	shield_sprite = Sprite2D.new()
	shield_sprite.texture = preload("res://asset/PNG/Effects/shield3.png")
	shield_sprite.scale = Vector2(1.2, 1.2)
	shield_sprite.modulate = Color(0.5, 0.8, 1.0, 0.0)
	add_child(shield_sprite)
	var shield_tween = create_tween().set_loops()
	shield_tween.tween_property(shield_sprite, "rotation", TAU, 4.0).from(0.0)

func apply_boost(type: BoostManager.BoostType, duration: float = 20.0):
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
	
	if _fire_timer > 0:
		_fire_timer -= delta
		
	if _fire_timer <= 0:
		shoot()
		var interval = fire_shoot
		if _active_boosts.has(BoostManager.BoostType.LASER_UPGRADE):
			interval *= 0.4 
		_fire_timer = interval

func shoot():
	_spawn_laser(muzzle.global_position)
	if _active_boosts.has(BoostManager.BoostType.LASER_UPGRADE):
		_spawn_laser(muzzle.global_position + Vector2(-30, 10))
		_spawn_laser(muzzle.global_position + Vector2(30, 10))
		_spawn_laser(muzzle.global_position + Vector2(-60, 25))
		_spawn_laser(muzzle.global_position + Vector2(60, 25))
	else:
		_spawn_laser(muzzle.global_position + Vector2(-25, 15))
		_spawn_laser(muzzle.global_position + Vector2(25, 15))

func _spawn_laser(pos):
	var laser = laser_scene.instantiate()
	laser.global_position = pos
	if "speed" in laser:
		laser.speed *= _laser_speed_mult
	laser_container.add_child(laser)
	if laser_sound and !laser_sound.playing: laser_sound.play()

func take_hit():
	if is_invincible or is_dying: return
	if has_shield: return 
	die()

func _physics_process(delta):
	if is_dying: return
	
	if touch_active:
		var drag_move = _last_drag_relative
		_last_drag_relative = Vector2.ZERO
		velocity = drag_move / delta
		global_position += drag_move
	else:
		var direction = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")).normalized()
		if direction != Vector2.ZERO:
			velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		move_and_slide()
	
	rotation = lerp_angle(rotation, deg_to_rad(clamp(velocity.x / SPEED, -1.5, 1.5) * 20.0), delta * 10.0)
	global_position = global_position.clamp(Vector2.ZERO, get_viewport_rect().size)

func die():
	if is_dying: return
	_active_boosts.clear()
	_laser_speed_mult = 1.0
	has_shield = false
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

func upgrade_fire_rate(): fire_shoot = max(0.1, fire_shoot - 0.05)
