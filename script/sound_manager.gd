extends Node
class_name SoundManager

## Efficient SFX management for mobile performance.
## Reuses AudioStreamPlayer nodes instead of frequent instantiation.

@export var pool_size: int = 8
var _pool: Array[AudioStreamPlayer] = []
var _next_index: int = 0

func _ready():
	for i in range(pool_size):
		var asp = AudioStreamPlayer.new()
		asp.bus = &"SFX"
		add_child(asp)
		_pool.append(asp)

func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0):
	if not stream: return
	
	# Simple round-robin pooling
	var asp = _pool[_next_index]
	_next_index = (_next_index + 1) % pool_size
	
	asp.stream = stream
	asp.volume_db = volume_db
	asp.pitch_scale = pitch_scale
	asp.play()
