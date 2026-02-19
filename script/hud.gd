extends Control

signal settings_pressed
signal missile_fire_pressed

@onready var score_label = $Score
@onready var settings_button = $SettingsButton

var score := 0:
	set(value):
		var old_score = score
		score = value
		if is_inside_tree() and score_label:
			score_label.text = "Score: " + str(score)
			if score > old_score:
				_pop_score()

@onready var hearts = [
	$LivesContainer/Heart1,
	$LivesContainer/Heart2,
	$LivesContainer/Heart3
]

@onready var laser_indicator = $LaserIndicator
@onready var laser_bar = $LaserIndicator/ProgressBar
@onready var missile_button = $MissileButton
@onready var shock_face = $ShockFace

var die_texture = preload("res://asset/PNG/Lives/Die.png")
var life_texture = preload("res://asset/PNG/Lives/Life.png")

func _ready():
	if OS.get_name() in ["iOS", "Android"]:
		var m = UIConstants.get_safe_margin()
		$ScoreBG.offset_top += m
		$ScoreBG.offset_bottom += m
		$Score.offset_top += m
		$Score.offset_bottom += m
		$LivesBG.offset_left += m
		$LivesContainer.offset_left += m
		$LivesContainer.offset_top += m
		$SettingsButton.offset_left -= m
		$SettingsButton.offset_right -= m
		$SettingsButton.offset_top += m
		$SettingsButton.offset_bottom += m
		$ShockFace.offset_left += m
		$ShockFace.offset_top += m
		$MissileButton.offset_left -= m
		$MissileButton.offset_right -= m
		$MissileButton.offset_top -= m
		$MissileButton.offset_bottom -= m
		$LaserIndicator.offset_top += m
	score_label.text = "Score: " + str(score)
	score_label.pivot_offset = score_label.size / 2
	for h in hearts:
		h.pivot_offset = h.size / 2
	
	if settings_button:
		settings_button.pivot_offset = settings_button.size / 2
		settings_button.pressed.connect(_on_settings_pressed)
	if missile_button:
		missile_button.button_down.connect(_on_missile_pressed)
		missile_button.visible = false
		missile_button.button_down.connect(func(): create_tween().tween_property(missile_button, "scale", Vector2(0.85, 0.85), 0.1))
		missile_button.button_up.connect(func(): create_tween().tween_property(missile_button, "scale", Vector2.ONE, 0.1))
		settings_button.button_down.connect(func(): create_tween().tween_property(settings_button, "scale", Vector2(0.8, 0.8), 0.1))
		settings_button.button_up.connect(func(): create_tween().tween_property(settings_button, "scale", Vector2.ONE, 0.1))
	if shock_face:
		_start_shock_face_idle()

func _on_settings_pressed():
	settings_pressed.emit()

func _pop_score():
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.15, 1.15), 0.05).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(score_label, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_CUBIC)

func update_lives(lives: int):
	for i in range(3):
		var heart = hearts[i]
		if i < lives:
			heart.texture = life_texture
			heart.modulate = Color.WHITE
		else:
			if heart.texture == life_texture:
				_animate_life_loss(heart)
			heart.texture = die_texture
			heart.modulate = Color(1, 1, 1, 0.6)

func show_laser_boost(current: float, total: float):
	if laser_indicator:
		laser_indicator.visible = true
		if laser_bar:
			laser_bar.max_value = total
			laser_bar.value = current

func hide_laser_boost():
	if laser_indicator:
		laser_indicator.visible = false

func show_missile_button(charges: int):
	if missile_button:
		missile_button.visible = charges > 0
		var lbl = missile_button.get_node_or_null("ChargesLabel")
		if lbl: lbl.text = str(charges)

func _on_missile_pressed():
	missile_fire_pressed.emit()

func _start_shock_face_idle():
	if not shock_face: return
	var idle = create_tween().set_loops()
	idle.tween_property(shock_face, "scale", Vector2(1.02, 1.02), 1.2).set_trans(Tween.TRANS_SINE)
	idle.tween_property(shock_face, "scale", Vector2(0.98, 0.98), 1.2).set_trans(Tween.TRANS_SINE)

func _animate_life_loss(heart: TextureRect):
	var tween = create_tween().set_parallel(true)
	tween.tween_property(heart, "scale", Vector2(1.5, 1.5), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(heart, "modulate", Color.RED, 0.15)
	
	await tween.finished
	
	var out = create_tween().set_parallel(true)
	out.tween_property(heart, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_CUBIC)
	out.tween_property(heart, "modulate", Color(1, 1, 1, 0.6), 0.2)
