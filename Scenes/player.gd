extends Sprite

const MOVE_SPEED = 50

enum {NONE, MOVE}
var STATE = NONE

# warning-ignore:unused_class_variable
var map_pos = Vector2()

var _target

signal move_finished

func move(p):
	_target = p
	STATE = MOVE

func _process(delta):
	match STATE:
		MOVE:
			var d = _target - position
			if d.length() <= MOVE_SPEED*delta:
				position = _target
				STATE = NONE
				emit_signal("move_finished")
			else:
				position += MOVE_SPEED * delta * d.normalized()