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
	global.map = self
	
	player.position = grid2local(Vector2(-2, HEIGHT-1))
	player.map_pos = Vector2(0, HEIGHT-1)
	player.move(grid2local(Vector2(0, HEIGHT-1)))
	map[Vector2(0, HEIGHT-1)] = player
	
	units.append(player)
	
	for u in get_children():
		if u != player:
			units.append(u)
			u.map_pos = local2grid(u.position)
			u.position = grid2local(u.map_pos)
			map[u.map_pos] = u
			u.connect("dead", self, "_on_dead_obj", [u])

func _on_dead_obj(u):
	map[u.map_pos] = null
	var i = units.find(u)
	if i < current_unit:
		current_unit -= 1
	units.remove(i)

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
		wait(obj, "move_finished")
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
				else:
					units[current_unit].turn(self)

func is_free(p):
	p = p.floor()
	return map.get(p) == null 

func is_in_room(p):
	p = p.floor()
	return p.x >= 0 and p.y >= 0 and p.x < WIDTH and p.y < HEIGHT

func is_exit(p):
	p = p.floor()
	return p.x == WIDTH and p.y >= HEIGHT-2 and p.y < HEIGHT

func grid2local(p):
	return (p + Vector2.ONE*1.5)*CELL_SIZE

func local2grid(p):
	return (p / CELL_SIZE).floor() - Vector2.ONE

func can_move_to(obj, p):
	p = p.floor()
	return (
		(is_in_room(p) or (
			obj == player and is_exit(p))
			) 
		and is_free(p)
	)

func can_attack(obj, p):
	p = p.floor()
	return (
		map.get(p, null) != null 
		and obj.map_pos != p
		and obj.can_attack(map[p])
	)

func get(p):
	return map.get(p.floor())

signal show_info(item)

func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		var p = get_local_mouse_position()
		if get_used_rect().has_point(p):
			var i = get(local2grid(p))
			if i and i != player:
				emit_signal("show_info", i)

func get_used_rect()->Rect2:
	return Rect2(CELL_SIZE, CELL_SIZE, WIDTH*CELL_SIZE, HEIGHT*CELL_SIZE)