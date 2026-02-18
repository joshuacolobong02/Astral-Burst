extends BaseEnemy

var orbit_angle = 0.0
@export var orbit_radius = 150.0
@export var orbit_speed = 2.0
var orbital_center = Vector2.ZERO

func _ready():
	super._ready()
	if orbital_center == Vector2.ZERO:
		orbital_center = Vector2(get_viewport_rect().size.x / 2, 200)

func _physics_process(delta):
	match type:
		Type.LINEAR:
			global_position.y += speed * delta
		Type.ORBITAL:
			orbit_angle += orbit_speed * delta
			var target_pos = orbital_center + Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
			global_position = global_position.lerp(target_pos, 1.0 - exp(-5.0 * delta))
		Type.INFINITY:
			orbit_angle += orbit_speed * delta
			# Infinity symbol (Lissajous curve)
			var target_offset = Vector2(
				cos(orbit_angle) * orbit_radius,
				(sin(2.0 * orbit_angle) / 2.0) * orbit_radius
			)
			var target_pos = orbital_center + target_offset
			global_position = global_position.lerp(target_pos, 1.0 - exp(-5.0 * delta))
		Type.ELITE:
			global_position.y += speed * 0.5 * delta
			# Add zig-zag movement (No shooting)
			var t = Time.get_ticks_msec() / 1000.0
			global_position.x += sin(t * 2.0) * 3.0
