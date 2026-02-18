extends Node2D

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
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
		var lt = create_tween()
		lt.tween_property($PointLight2D, "energy", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	if animated_sprite.sprite_frames.has_animation("explosion_boss"):
		animated_sprite.play("explosion_boss")
	elif animated_sprite.sprite_frames.has_animation("boss_explosion"):
		animated_sprite.play("boss_explosion")
	else:
		animated_sprite.play("Explosion")

func _on_animation_finished():
	# Wait for particles if they are still emitting
	if has_node("Sparks") and $Sparks.emitting:
		await get_tree().create_timer(0.5).timeout
	queue_free()
