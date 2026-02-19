extends Node2D

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
	reset_pool_state()

func reset_pool_state():
	# Randomize rotation for variety
	rotation = randf_range(0, TAU)
	
	# Scale pop effect
	scale = Vector2.ZERO
	var st = create_tween()
	st.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	st.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Start particles
	if has_node("Sparks"):
		$Sparks.emitting = true
	
	# Light flash
	if has_node("PointLight2D"):
		$PointLight2D.enabled = true
		$PointLight2D.energy = 1.0 # Assuming 1.0 is default
		var lt = create_tween()
		lt.tween_property($PointLight2D, "energy", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	var asp = animated_sprite if is_instance_valid(animated_sprite) else get_node_or_null("AnimatedSprite2D")
	if asp and asp.sprite_frames:
		if asp.sprite_frames.has_animation("explosion_boss"):
			asp.play("explosion_boss")
		elif asp.sprite_frames.has_animation("boss_explosion"):
			asp.play("boss_explosion")
		else:
			asp.play("Explosion")

func _on_animation_finished():
	# Wait for particles if they are still emitting
	if has_node("Sparks") and $Sparks.emitting:
		await get_tree().create_timer(0.5).timeout
	
	var game = get_tree().current_scene
	if game and "pool_manager" in game and is_instance_valid(game.pool_manager):
		game.pool_manager.return_to_pool(self, "res://scene/explode_animate.tscn")
	else:
		queue_free()
