extends Area2D

# Unified with BoostManager for clean scalability
signal despawned  # Emitted when boost leaves screen without being collected

@export var boost_type: BoostManager.BoostType = BoostManager.BoostType.LASER_UPGRADE
@export var is_coin: bool = false # Special case for score-only pickups
@export var speed: float = 280.0  # Fall like meteors
@export var rotation_speed: float = 90.0  # Rotate as it falls

var boost_sound = preload("res://asset/Bonus/BoostCollect.ogg")
var coin_sound = preload("res://asset/Bonus/CoinCollect.ogg")
var _collected := false

func _ready():
	add_to_group("powerup")
	# Entry Animation - match meteor size (scale 0.25)
	scale = Vector2(0.1, 0.1)
	create_tween().tween_property(self, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK)
	
	z_index = 150 
	_add_enhanced_glow()
	
	# No loop rotation - we rotate in _process as it falls
	
	# Floating sprite animation
	var sprite = $Sprite2D
	if sprite:
		var base_scale = sprite.scale
		var ft = create_tween().set_loops()
		ft.tween_property(sprite, "scale:y", base_scale.y * 1.2, 0.5).set_trans(Tween.TRANS_SINE)
		ft.tween_property(sprite, "scale:y", base_scale.y * 0.8, 0.5).set_trans(Tween.TRANS_SINE)
		
		if is_coin:
			# flipping animation for coin
			var rt = create_tween().set_loops()
			rt.tween_property(sprite, "scale:x", -base_scale.x, 0.6).set_trans(Tween.TRANS_SINE)
			rt.tween_property(sprite, "scale:x", base_scale.x, 0.6).set_trans(Tween.TRANS_SINE)

func _add_enhanced_glow():
	var color = _get_type_color()
	var glow = Sprite2D.new()
	glow.texture = preload("res://asset/PNG/Effects/star1.png")
	glow.modulate = color; glow.modulate.a = 0.6; glow.scale = Vector2(2.5, 2.5); glow.show_behind_parent = true
	add_child(glow)
	
	var gt = create_tween().set_loops()
	gt.tween_property(glow, "modulate:a", 0.2, 0.6); gt.tween_property(glow, "modulate:a", 0.7, 0.6)
	
	var ring = Sprite2D.new()
	ring.texture = preload("res://asset/PNG/Effects/star3.png")
	ring.modulate = color; ring.modulate.a = 0.3; ring.scale = Vector2(1.0, 1.0)
	add_child(ring)
	
	var rt = create_tween().set_loops()
	rt.tween_property(ring, "scale", Vector2(4.0, 4.0), 1.2)
	rt.parallel().tween_property(ring, "modulate:a", 0.0, 1.2)
	rt.tween_callback(func(): ring.scale = Vector2.ONE; ring.modulate.a = 0.3)

func _get_type_color() -> Color:
	if is_coin: return Color(1.0, 0.8, 0.0, 1.0) # Gold
	match boost_type:
		BoostManager.BoostType.LASER_UPGRADE: return Color(0.2, 0.5, 1.0, 1.0) # Blue
		BoostManager.BoostType.LASER_SPEED: return Color(1.0, 0.3, 0.1, 1.0) # Orange/Red
		BoostManager.BoostType.MISSILE: return Color(1.0, 0.5, 0.0, 1.0) # Orange
		BoostManager.BoostType.SHIELD: return Color(0.2, 1.0, 0.2, 1.0) # Green
		BoostManager.BoostType.BOOST_BAG: return Color(0.9, 0.4, 0.9, 1.0) # Purple gift
	return Color.WHITE

func _process(delta):
	global_position.y += speed * delta
	rotation += deg_to_rad(rotation_speed) * delta
	if global_position.y > 1100:
		if !_collected and !is_coin:
			despawned.emit()
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		call_deferred("_do_collect", body)

func _do_collect(body: Node):
	if _collected or !is_instance_valid(body): return
	_collected = true
	set_deferred("monitoring", false)
	if is_coin:
		if get_tree().current_scene.has_method("add_score"):
			get_tree().current_scene.add_score(10)
		_play_sound(coin_sound)
	else:
		var apply_type = boost_type
		if boost_type == BoostManager.BoostType.BOOST_BAG:
			apply_type = [BoostManager.BoostType.LASER_UPGRADE, BoostManager.BoostType.LASER_SPEED, BoostManager.BoostType.MISSILE, BoostManager.BoostType.SHIELD].pick_random()
		body.apply_boost(apply_type, 20.0)
		_play_sound(boost_sound)
	var ct = create_tween().set_parallel(true)
	if boost_type != BoostManager.BoostType.MISSILE:
		ct.tween_property(self, "scale", Vector2(3.0, 3.0), 0.2)
	ct.tween_property(self, "modulate:a", 0.0, 0.15)
	ct.chain().tween_callback(queue_free)

func _play_sound(stream):
	if stream:
		var game = get_tree().current_scene
		if game and "sfx_manager" in game and is_instance_valid(game.sfx_manager):
			game.sfx_manager.play_sfx(stream)
		else:
			var sfx = AudioStreamPlayer.new()
			sfx.stream = stream; sfx.bus = &"SFX"; get_tree().current_scene.add_child(sfx)
			sfx.play(); sfx.finished.connect(sfx.queue_free)
