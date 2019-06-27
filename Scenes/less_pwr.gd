extends Control

const TIME = 5
const MOVE_SPEED = 3

var _timer = TIME

func set_type(t):
	$icon.texture = global.TYPE2ICON[t]

func set_position(p):
	rect_position = p
	rect_position.x -= 48 / 2 / 3
	rect_position.y -= 27 / 3

func _process(delta):
	rect_position.y -= delta*MOVE_SPEED
	_timer -= delta
	if _timer <= 0:
		queue_free()
	else:
		modulate.a = _timer / TIME