extends ColorRect

const BLINK_TIME = 0.15
const PARTICLES_TIME = 0.5

signal finished

var _timer = 0

func play(blood_dir : Vector2):
	_timer = 0
	self_modulate.a = 1
	$blood_particles.emitting = true
	$blood_particles.rotation = 0
	blood_dir = $blood_particles.global_transform.basis_xform(blood_dir)
	$blood_particles.rotation = blood_dir.angle()
	set_process(true)

func _ready():
	set_process(false)

func _process(delta):
	_timer += delta
	self_modulate.a = 1 if _timer < BLINK_TIME else 0
	if _timer > PARTICLES_TIME:
		set_process(false)
		emit_signal("finished")