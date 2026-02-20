extends Control

@onready var sound_slider = %SoundSlider
@onready var music_slider = %MusicSlider
@onready var graphics_option = %GraphicsOption
@onready var save_button = %SaveButton
@onready var exit_button = %ExitButton

func _ready():
	# Initial setup
	_load_settings()
	
	# Connect signals
	save_button.pressed.connect(_on_save_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	sound_slider.value_changed.connect(_on_sound_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	
	# Entrance animation
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func _load_settings():
	# Load from AudioServer
	var sfx_index = AudioServer.get_bus_index("SFX")
	if sfx_index != -1:
		sound_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_index)) * 100
	else:
		sound_slider.value = 80
		
	var music_index = AudioServer.get_bus_index("Music")
	if music_index == -1:
		# Fallback to Master if Music bus doesn't exist
		music_index = AudioServer.get_bus_index("Master")
		
	if music_index != -1:
		music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_index)) * 100
	else:
		music_slider.value = 70
		
	# Graphics placeholder
	graphics_option.selected = 1

func _on_sound_volume_changed(value: float):
	_set_bus_volume("SFX", value)

func _on_music_volume_changed(value: float):
	# Try Music bus first, then Master
	if AudioServer.get_bus_index("Music") != -1:
		_set_bus_volume("Music", value)
	else:
		_set_bus_volume("Master", value)

func _set_bus_volume(bus_name: String, value: float):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		var db_value = linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(bus_index, db_value)
		# Mute if value is 0
		AudioServer.set_bus_mute(bus_index, value <= 0)

func _on_save_pressed():
	# Save logic here (could persist to a file)
	_play_click_anim(save_button)
	await get_tree().create_timer(0.2).timeout
	_close()

func _on_exit_pressed():
	_play_click_anim(exit_button)
	await get_tree().create_timer(0.2).timeout
	_close()

func _close():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	queue_free()

func _play_click_anim(btn: Control):
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.1)
