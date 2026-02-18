extends Area2D

signal destroyed(instance)

@export var speed = 1000
@export var damage = 1

var _base_speed: float
var _is_being_destroyed := false

func _ready():
	_base_speed = speed
	# Visual stretch effect on spawn
	_stretch_anim()

func _stretch_anim():
	var tween = create_tween().set_parallel(true)
	tween.tween_property($Sprite2D, "scale:y", 0.08, 0.1).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($Sprite2D, "scale:x", 0.03, 0.1).set_trans(Tween.TRANS_CUBIC)

func reset(pos: Vector2, speed_mult: float = 1.0):
	_is_being_destroyed = false
	speed = _base_speed * speed_mult
	global_position = pos
	$Sprite2D.scale = Vector2(0.01, 0.01) # Small start for stretch
	_stretch_anim()
	show()
	set_physics_process(true)
	set_deferred("monitorable", true)
	set_deferred("monitoring", true)

func _physics_process(delta):
	global_position.y += -speed * delta


func _on_visible_on_screen_notifier_2d_screen_exited():
	_destroy()


func _on_area_entered(area):
	if _is_being_destroyed:
		return
	if area is BaseEnemy:
		area.take_damage(damage)
	elif area is MeteorProjectile:
		area.take_damage(damage)
	call_deferred("_destroy")

func _destroy():
	if _is_being_destroyed:
		return
	_is_being_destroyed = true
	
	hide()
	set_physics_process(false)
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	destroyed.emit(self)
