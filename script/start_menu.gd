extends Control

signal start_game
signal countdown_started

@onready var menu_content = $MenuContent
@onready var buttons_container = %Buttons
@onready var play_button = %PlayButton
@onready var settings_button = %SettingsButton
@onready var quit_button = %QuitButton
@onready var title = %Title
@onready var countdown_texture = %CountdownTexture
@onready var countdown_sfx = %CountdownSFX

var _transitioning := false
var _breathing_tween: Tween
var _active_tweens: Dictionary = {}

var countdown_images = {
	"3": preload("res://asset/PNG/Countdown/3.png"),
	"2": preload("res://asset/PNG/Countdown/2.png"),
	"1": preload("res://asset/PNG/Countdown/1.png"),
	"GO": preload("res://asset/PNG/Countdown/GO!.png")
}

func _ready():
	# Initial visibility
	modulate.a = 0
	if countdown_texture: countdown_texture.visible = false
	if menu_content:
		menu_content.visible = true
		menu_content.scale = Vector2.ONE
		menu_content.modulate.a = 1.0
	
	# Pre-warm countdown textures to avoid first-use lag
	if countdown_texture:
		for img in countdown_images.values():
			countdown_texture.texture = img
			await get_tree().process_frame
		countdown_texture.texture = null
	
	# Wait for layout engine to calculate sizes
	await get_tree().process_frame
	if OS.get_name() in ["iOS", "Android"] and title:
		title.offset_top += UIConstants.get_safe_margin()
	# Set pivots for all animated elements
	_setup_pivots()
	
	# Setup interaction signals
	_setup_signals()
	
	# Start entrance sequence
	_animate_entrance()

func _setup_signals():
	if play_button and not play_button.pressed.is_connected(_on_start_button_pressed):
		play_button.pressed.connect(_on_start_button_pressed)
	if settings_button and not settings_button.pressed.is_connected(_on_settings_button_pressed):
		settings_button.pressed.connect(_on_settings_button_pressed)
	if quit_button and not quit_button.pressed.is_connected(_on_quit_button_pressed):
		quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Add hover/touch feedback to ALL buttons
	var buttons = [play_button, settings_button, quit_button]
	for btn in buttons:
		if not btn: continue
		# Disconnect if already connected to prevent duplicates
		if btn.mouse_entered.is_connected(_on_button_hover): btn.mouse_entered.disconnect(_on_button_hover)
		if btn.mouse_exited.is_connected(_on_button_hover): btn.mouse_exited.disconnect(_on_button_hover)
		
		btn.mouse_entered.connect(_on_button_hover.bind(btn, true))
		btn.mouse_exited.connect(_on_button_hover.bind(btn, false))
		btn.button_down.connect(_on_button_down.bind(btn))
		btn.button_up.connect(_on_button_up.bind(btn))

func _setup_pivots():
	if title: title.pivot_offset = title.size / 2
	if play_button: play_button.pivot_offset = play_button.size / 2
	if settings_button: settings_button.pivot_offset = settings_button.size / 2
	if quit_button: quit_button.pivot_offset = quit_button.size / 2
	if buttons_container: buttons_container.pivot_offset = buttons_container.size / 2

func _animate_entrance():
	var tween = create_tween().set_parallel(true)
	
	# Fade in the whole menu
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	
	# Title pop-in
	if title:
		title.scale = Vector2(0.5, 0.5)
		title.modulate.a = 0
		tween.tween_property(title, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_OUT)
		tween.tween_property(title, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Staggered button entrance
	var buttons = [play_button, settings_button, quit_button]
	for i in range(buttons.size()):
		var btn = buttons[i]
		if not btn: continue
		btn.modulate.a = 0
		btn.scale = Vector2(0.8, 0.8)
		var delay = 0.3 + (i * 0.1)
		tween.tween_property(btn, "modulate:a", 1.0, 0.4).set_delay(delay)
		tween.tween_property(btn, "scale", Vector2.ONE, 0.5).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	_start_idle_animations()

func _start_idle_animations():
	if _transitioning: return
	
	# Floating Title effect
	if title:
		var float_tween = create_tween().set_loops()
		float_tween.tween_property(title, "position:y", title.position.y + 8, 2.0).set_trans(Tween.TRANS_SINE)
		float_tween.tween_property(title, "position:y", title.position.y, 2.0).set_trans(Tween.TRANS_SINE)
	
	# Subtle breathing for play button
	if play_button:
		_breathing_tween = create_tween().set_loops()
		_breathing_tween.tween_property(play_button, "scale", Vector2(1.04, 1.04), 1.2).set_trans(Tween.TRANS_SINE)
		_breathing_tween.tween_property(play_button, "scale", Vector2(0.98, 0.98), 1.2).set_trans(Tween.TRANS_SINE)

func _on_button_hover(btn: Control, is_hover: bool):
	if _transitioning: return
	
	# Skip hover effects on mobile
	if DisplayServer.get_name() == "Android" or DisplayServer.get_name() == "iOS":
		return
		
	# Handle breathing for play button
	if btn == play_button and _breathing_tween:
		if is_hover: _breathing_tween.pause()
		else: _breathing_tween.play()
	
	var target_scale = Vector2(1.15, 1.15) if is_hover else Vector2.ONE
	var target_rot = 2.0 if is_hover else 0.0
	var target_mod = Color(1.2, 1.2, 1.2, 1.0) if is_hover else Color.WHITE
	
	_tween_button(btn, target_scale, target_rot, 0.2, target_mod)
	
	if is_hover:
		_play_sfx(1.5, -20)

func _on_button_down(btn: Control):
	if _transitioning: return
	if btn == play_button and _breathing_tween: _breathing_tween.pause()
	_tween_button(btn, Vector2(0.85, 0.85), 0.0, 0.1, Color(0.8, 0.8, 0.8, 1.0))
	_play_sfx(0.8, -10)

func _on_button_up(btn: Control):
	if _transitioning: return
	# Return to neutral or hover state
	var is_hovering = btn.get_global_rect().has_point(get_global_mouse_position())
	var mobile = DisplayServer.get_name() == "Android" or DisplayServer.get_name() == "iOS"
	
	var target_scale = Vector2(1.15, 1.15) if is_hovering and not mobile else Vector2.ONE
	var target_rot = 2.0 if is_hovering and not mobile else 0.0
	var target_mod = Color(1.2, 1.2, 1.2, 1.0) if is_hovering and not mobile else Color.WHITE
	
	_tween_button(btn, target_scale, target_rot, 0.1, target_mod)
	
	if btn == play_button and _breathing_tween and not is_hovering: 
		_breathing_tween.play()

func _tween_button(btn: Control, p_scale: Vector2, p_rotation: float = 0.0, duration: float = 0.2, modulate_color: Color = Color.WHITE):
	if _active_tweens.has(btn): _active_tweens[btn].kill()
	var tween = create_tween().set_parallel(true)
	tween.tween_property(btn, "scale", p_scale, duration).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(btn, "rotation_degrees", p_rotation, duration).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(btn, "modulate", modulate_color, duration).set_trans(Tween.TRANS_CUBIC)
	_active_tweens[btn] = tween

func _play_sfx(pitch: float, volume: float):
	if countdown_sfx:
		var sfx = countdown_sfx.duplicate()
		add_child(sfx)
		sfx.pitch_scale = pitch
		sfx.volume_db = volume
		sfx.play()
		sfx.finished.connect(sfx.queue_free)

func _on_start_button_pressed():
	if _transitioning: return
	_play_click_anim(play_button)
	_start_transition()

func _on_quit_button_pressed():
	if _transitioning: return
	_play_click_anim(quit_button)
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _on_settings_button_pressed():
	if _transitioning: return
	_play_click_anim(settings_button)
	
	var settings_scene = preload("res://scene/settings_menu.tscn")
	var settings_instance = settings_scene.instantiate()
	add_child(settings_instance)

func _play_click_anim(btn: Control):
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_CUBIC)

func _start_transition():
	if _transitioning: return
	_transitioning = true
	
	if _breathing_tween: _breathing_tween.kill()
	for t in _active_tweens.values(): t.kill()
	
	# Disable buttons immediately
	if play_button: play_button.disabled = true
	if settings_button: settings_button.disabled = true
	if quit_button: quit_button.disabled = true
	
	# Fade and zoom out the menu first
	var tween = create_tween().set_parallel(true)
	if menu_content:
		tween.tween_property(menu_content, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
		tween.tween_property(menu_content, "scale", Vector2(1.2, 1.2), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	await tween.finished
	if menu_content: menu_content.visible = false
	
	# Brief cinematic pause before countdown
	await get_tree().create_timer(0.4).timeout
	
	start_countdown()

func start_countdown():
	# Ensure transitioning is true even if called directly
	_transitioning = true
	
	countdown_started.emit()
	countdown_texture.modulate.a = 0.0
	countdown_texture.scale = Vector2(0.3, 0.3)
	countdown_texture.visible = true

	# Increased duration from 0.6 to 0.8 for a better pace
	for i in ["3", "2", "1"]:
		_play_sfx(1.0, -10)
		await show_countdown_image(i, 0.8)

	_play_sfx(1.2, -10)
	show_countdown_image("GO", 0.8) # Removed 'await' to emit start_game immediately
	
	_transitioning = false
	start_game.emit()
	
	# Small delay before hiding texture to allow the 'GO' animation to finish in background
	await get_tree().create_timer(0.8).timeout
	countdown_texture.visible = false

func show_countdown_image(key, duration = 0.8):
	countdown_texture.texture = countdown_images[key]
	await get_tree().process_frame
	countdown_texture.pivot_offset = countdown_texture.size / 2
	
	var tween = create_tween().set_parallel(true)
	countdown_texture.scale = Vector2(0.2, 0.2)
	countdown_texture.modulate.a = 0.0
	
	# Reduced target scale from Vector2.ONE to Vector2(0.75, 0.75)
	var target_scale = Vector2(0.75, 0.75)
	tween.tween_property(countdown_texture, "scale", target_scale, duration * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(countdown_texture, "modulate:a", 1.0, duration * 0.2)
	
	await get_tree().create_timer(duration * 0.6).timeout
	
	var out_tween = create_tween().set_parallel(true)
	out_tween.tween_property(countdown_texture, "modulate:a", 0.0, duration * 0.3)
	out_tween.tween_property(countdown_texture, "scale", target_scale * 1.3, duration * 0.3)
	await out_tween.finished
