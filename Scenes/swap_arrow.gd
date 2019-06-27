extends Sprite

const MOVE_SPEED = 40
const TIME = 0.8

var _timer = 0
var _dir : Vector2

func play(dir : Vector2):
	rotation = dir.angle()
	self._dir = dir.normalized()
	_timer = TIME
	show()
	set_process(true)

func _ready():
	set_process(false)

func _process(delta):
	_timer -= delta
	position += _dir * MOVE_SPEED * delta
	modulate.a = 0.7*_timer/TIME
	if _timer <= 0:
		hide()