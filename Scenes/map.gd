extends Sprite

const WIDTH = 7
const HEIGHT = 5
const CELL_SIZE = 16

enum {NONE, WAIT}
var STATE = NONE

var map = {}
onready var player = $player

var units = []
var current_unit = 0

func _ready():
	units.append(player)
	global.map = self
	player.position = grid2local(Vector2(-1, HEIGHT-1))
	player.map_pos = Vector2(0, HEIGHT-1)
	player.move(grid2local(Vector2(0, HEIGHT-1)))
	map[Vector2(0, HEIGHT-1)] = player

var _wait_queue = []

class Waiter:
	var finished = false
	func _init(obj, s):
		obj.connect(s, self, 'on_finish', [], CONNECT_ONESHOT)
	func on_finish():
		finished = true

func wait(obj, signal_name):
	_wait_queue.append(Waiter.new(obj, signal_name))

func move(obj, p):
	p = p.floor()
	if map.get(p, null) == null:
		map[p] = obj
		map[obj.map_pos] = null
		obj.map_pos = p
		obj.move(grid2local(p))
		obj.connect("move_finished", self, "next", [], CONNECT_ONESHOT | CONNECT_DEFERRED)
	else:
		push_error("Error move")

signal player_turn;

func next():
	STATE = WAIT

# warning-ignore:unused_argument
func _process(delta):
	match STATE:
		WAIT:
			for i in range(_wait_queue.size()-1,-1,-1):
				if _wait_queue[i].finished:
					_wait_queue.remove(i)
			if _wait_queue.size() == 0:
				STATE = NONE
				if len(units) == 0:
					return
				current_unit = (current_unit + 1) % len(units)
				if units[current_unit] == player:
					emit_signal("player_turn")

func is_in_room(p):
	p = p.floor()
	return p.x >= 0 and p.y >= 0 and p.x < WIDTH and p.y < HEIGHT

func grid2local(p):
	return (p + Vector2.ONE*1.5)*CELL_SIZE

func local2grid(p):
	return (p / CELL_SIZE).floor() - Vector2.ONE