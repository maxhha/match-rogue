extends Control

const TIME = 3
const MOVE_SPEED = 3*4
const HEIGHT = 27

var _timer = TIME

func set_type(t):
	$icon.texture = global.TYPE2ICON[t]

func set_pos(p):
	rect_global_position = p
	rect_global_position.x -= 48 / 2 
	rect_global_position.y -= HEIGHT

func _process(delta):
	rect_position.y -= delta*MOVE_SPEED
	_timer -= delta
	if _timer <= 0:
		queue_free()
	else:
		modulate.a = _timer / TIME