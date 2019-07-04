extends AnimatedSprite

enum {NONE, MOVE, DEAD}
var STATE = NONE

const MOVE_SPEED = 40
const DEAD_TIME = 0.3

# warning-ignore:unused_class_variable
var map_pos = Vector2()

# warning-ignore:unused_signal
signal move_finished
# warning-ignore:unused_signal
signal dead

var _target
var _timer

func move(p):
	_target = p
	STATE = MOVE

func is_on_floor():
	var under = map_pos + Vector2.DOWN
	return global.map.is_wall(under)

func dead_fade_out(delta):
	if _timer > 0:
		_timer -= delta
		self_modulate.a = _timer/DEAD_TIME