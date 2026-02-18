extends Node

@onready var music_player: AudioStreamPlayer = $"../SFX/MusicPlayer"

var base_pitch = 1.0
var target_pitch = 1.0
var intensity_level = 0.0 # 0.0 to 1.0

func _ready():
	if music_player:
		if !music_player.stream.loop:
			# If the stream resource itself doesn't loop, we can force loop it here or manually restart
			music_player.finished.connect(_on_music_finished)
		music_player.play()

func _process(delta):
	if !music_player: return
	
	# Smoothly interpolate pitch to target
	music_player.pitch_scale = move_toward(music_player.pitch_scale, target_pitch, delta * 0.5)

func set_intensity(level: float):
	# Level 0.0 = Normal
	# Level 1.0 = High Intensity (Boss, low health, etc)
	intensity_level = clamp(level, 0.0, 1.0)
	
	# Map intensity to pitch (1.0 to 1.15) - subtle speed up
	target_pitch = base_pitch + (intensity_level * 0.15)

func _on_music_finished():
	# Ensure music loops
	music_player.play()

func stop_music():
	if music_player:
		music_player.stop()

func fade_out(duration: float = 1.0):
	if music_player and music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -40.0, duration).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(music_player.stop)

func play_music():
	if music_player and !music_player.playing:
		music_player.volume_db = -10.0 # Reset volume
		music_player.play()
