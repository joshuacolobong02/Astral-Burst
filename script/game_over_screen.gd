extends Control

signal restart

@onready var panel = $Panel
@onready var score_label = $Panel/Score
@onready var high_score_label = $Panel/HighScore
@onready var restart_button = $Panel/RestartButton

var _final_score := 0
var _active_tweens: Dictionary = {}

func _ready():
	visible = false
	modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	
	# Wait for layout to ensure sizes are correct
	await get_tree().process_frame
	panel.pivot_offset = panel.size / 2
	restart_button.pivot_offset = restart_button.size / 2
	
	# Add mobile touch feedback
	restart_button.button_down.connect(_on_button_down.bind(restart_button))
	restart_button.button_up.connect(_on_button_up.bind(restart_button))

func show_screen():
	# Kill any existing tweens
	for t in _active_tweens.values(): if t: t.kill()
	_active_tweens.clear()
	
	visible = true
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_active_tweens["entrance"] = tween
	
	# Animate score counter
	var score_tween = create_tween()
	score_tween.tween_method(set_score_text, 0, _final_score, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_active_tweens["score"] = score_tween
	
	await tween.finished
	_start_button_pulse()

func _start_button_pulse():
	var pulse = create_tween().set_loops()
	pulse.set_parallel(true)
	pulse.tween_property(restart_button, "scale", Vector2(1.06, 1.06), 0.8).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(restart_button, "modulate", Color(1.1, 1.1, 1.3, 1.0), 0.8).set_trans(Tween.TRANS_SINE)
	pulse.set_parallel(false)
	pulse.tween_property(restart_button, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_SINE)
	pulse.set_parallel(true)
	pulse.tween_property(restart_button, "modulate", Color.WHITE, 0.8).set_trans(Tween.TRANS_SINE)
	_active_tweens["pulse"] = pulse

func _on_button_down(btn: Control):
	if _active_tweens.has("pulse"): _active_tweens["pulse"].kill()
	create_tween().tween_property(btn, "scale", Vector2(0.9, 0.9), 0.1).set_trans(Tween.TRANS_CUBIC)

func _on_button_up(btn: Control):
	# Return to neutral
	create_tween().tween_property(btn, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_CUBIC)
	_start_button_pulse()

func set_score_text(value: int):
	score_label.text = "Score: " + str(value)

func _on_restart_button_pressed() -> void:
	# Snappy exit animation
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "scale", Vector2(1.1, 1.1), 0.2).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	visible = false
	restart.emit()
	
func set_score(value):
	_final_score = value
	score_label.text = "Score: 0"

func high_set_score(value):
	high_score_label.text = "Hi-Score: " + str(value)
