class_name EnemyLaser extends Area2D

@export var speed = 600
@export var damage = 1

var direction := Vector2.DOWN

func _ready():
	# Visual stretch effect on spawn, respecting base scale from scene
	var base_scale = $Sprite2D.scale
	$Sprite2D.scale = base_scale * 0.1 # Start small
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property($Sprite2D, "scale:y", base_scale.y * 1.5, 0.1).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($Sprite2D, "scale:x", base_scale.x * 0.8, 0.1).set_trans(Tween.TRANS_CUBIC)
	rotation = direction.angle() + PI/2

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.die()
		queue_free()

func _on_area_entered(area):
	# Optional: interaction with player lasers or other objects
	pass
