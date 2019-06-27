extends Sprite

const MOVE_SPEED = 400
const DESTROY_TIME = 0.25
const ITEM_SIZE = (16+2)*4

signal finish_move
signal finish_destroy

enum STATES{NONE, MOVE, DESTROY}
var STATE = STATES.NONE
var _start
var _target 
var _timer = 0

func set_color(c):
	frame = c

func move(p):
	_target = p
	STATE = STATES.MOVE
	if position.y < 0:
		self_modulate.a = 0
	
func destroy():
	_start = position + Vector2.ONE*ITEM_SIZE/2
	STATE = STATES.DESTROY
	_timer = 0

var hint_move = Vector2()

func hint():
	hint_move += Vector2(8, 0).rotated((randi() % 8) * TAU / 8)
	position += hint_move

func on_focus_enter():
	position -= hint_move
	hint_move = Vector2()
	$bg_color.show()
func on_focus_exit():
	$bg_color.hide()

func _process(delta):
	match STATE:
		STATES.MOVE:
			var d = _target - position
			self_modulate.a = clamp((ITEM_SIZE+position.y)/ITEM_SIZE, 0, 1)
			if d.length() <= MOVE_SPEED*delta:
				position = _target
				STATE = STATES.NONE
				self_modulate.a = 1
				emit_signal('finish_move')
			else:
				position += d.clamped(MOVE_SPEED*delta)
			
				
		STATES.DESTROY:
			_timer = delta+_timer
			if _timer < DESTROY_TIME:
				var k = _timer/DESTROY_TIME
				var s = 1 + k
				scale = Vector2.ONE*s*4
				position = _start - Vector2.ONE*s/2*ITEM_SIZE
				self_modulate.a = 1-k
			else:
				emit_signal("finish_destroy")
				queue_free()