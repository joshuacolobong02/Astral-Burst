extends Node2D

func _ready():
	reset_pool_state()

func reset_pool_state():
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("explode")
		if not $AnimationPlayer.animation_finished.is_connected(_on_animation_finished):
			$AnimationPlayer.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(_anim_name):
	var game = get_tree().current_scene
	if game and "pool_manager" in game and is_instance_valid(game.pool_manager):
		game.pool_manager.return_to_pool(self, "res://scene/explosion.tscn")
	else:
		queue_free()
