extends ParallaxBackground
class_name ParallaxManager

@export var scroll_speed: float = 600.0
@export var drift_speed: float = 5.0

var _manual_scroll_offset := Vector2.ZERO
var _planet_layers_config: Array[Dictionary] = []
var _target_scroll_speed: float = 600.0

func setup(config: Array[Dictionary]):
	_planet_layers_config = config
	for p in _planet_layers_config:
		p.layer.motion_scale = Vector2.ZERO

func update_parallax(delta: float, current_stage_idx: int, player_pos: Vector2):
	var stage_speed_mult = 1.0 + (float(current_stage_idx) * 0.1)
	scroll_speed = move_toward(scroll_speed, _target_scroll_speed, delta * 100.0)
	var current_scroll_speed = scroll_speed * stage_speed_mult
	
	_manual_scroll_offset.y += delta * current_scroll_speed
	_manual_scroll_offset.x += delta * drift_speed
	
	var player_parallax = Vector2.ZERO
	player_parallax.x = (player_pos.x - 201) * -0.05
	player_parallax.y = (player_pos.y - 437) * -0.02
	
	scroll_offset = (_manual_scroll_offset + player_parallax).round()
	
	for p in _planet_layers_config:
		if p.layer.visible:
			p.layer.motion_offset.y += current_scroll_speed * delta * p.depth
			p.sprite.rotation += delta * p.rot

func set_target_speed(p_speed: float):
	_target_scroll_speed = p_speed

func reset_offset():
	_manual_scroll_offset = Vector2.ZERO
	scroll_offset = Vector2.ZERO
