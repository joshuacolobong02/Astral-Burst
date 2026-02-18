extends ParallaxLayer

@export var scroll_speed := 120.0
var bg_height := 0.0

func _ready():
	bg_height = $BG1.texture.get_height()

func _process(delta):
	motion_offset.y += scroll_speed * delta

	if motion_offset.y >= bg_height:
		motion_offset.y -= bg_height
