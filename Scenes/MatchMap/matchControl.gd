tool
extends Control

const HINT_TIMEOUT = 15
var _hint_timer = 0

var score = 0 setget set_score
var count_swaps = 0 setget set_count_swaps
var can_swap = true setget set_can_swap

func set_can_swap(s):
	can_swap = s

signal score_changed(new_score)
signal count_swaps_changed(new_count_swaps)
signal element_removed(type)
signal update_finished()

func set_score(s):
	score = s
	emit_signal("score_changed", s)

func set_count_swaps(s):
	count_swaps = s
	emit_signal("count_swaps_changed", s)

const ITEM_SIZE = (16 + 2)*4 # (item + border) * scale

export (int) var XCOUNT = 5 setget set_xcount
export (int) var YCOUNT = 5 setget set_ycount

func set_xcount(c):
	XCOUNT = c
	update_min_size()

func set_ycount(c):
	YCOUNT = c
	update_min_size()

func update_min_size():
	rect_min_size = Vector2(XCOUNT, YCOUNT)*ITEM_SIZE
	click_rect.size = Vector2(XCOUNT, YCOUNT)*ITEM_SIZE

enum STATES{HINT, NONE, PRESSED, UPDATE, WAIT}

var STATE = STATES.HINT

var Slot = preload("slot.tscn")
var Item = preload("item.tscn")
var items = {}
var match_map

var click_rect = Rect2(Vector2(), Vector2(XCOUNT, YCOUNT)*ITEM_SIZE)

var _create_items_y = []

func _ready():
	if not Engine.is_editor_hint():
		STATE = STATES.NONE

		#setup match3 map
		var M = preload("res://Scripts/MatchMap.gd")
		randomize()
		match_map = M.new(XCOUNT, YCOUNT);
		
		for id in range(4):
			match_map.add_type(M.T.new(id, 1, 1 << id))
		
		match_map.create_cells()
		while true:
			match_map.fill_random()
			if match_map.detect_possible_swaps():
				break
		
		for x in range(XCOUNT):
			_create_items_y.append(0)
			for y in range(YCOUNT):
				var p = Vector2(x,y)
				var s = Slot.instance()
				add_child(s)
				s.position = grid2local(p)
				create_item(
					p,
					match_map.get_type_at(p),
					false)
		
		match_map.connect('swap', self, '_swap_items')
		match_map.connect('create_item', self, "create_item", [true])
		match_map.connect('move_item', self, '_on_move_item')
		match_map.connect('remove_chain', self, '_on_chain_remove')
		
	update_min_size()

var _wait_queue = []

class Waiter:
	var finished = false
	func _init(obj, s):
		obj.connect(s, self, 'on_finish', [], CONNECT_ONESHOT)
	func on_finish():
		finished = true

func create_item(p, colorID, animate):
	var r = Item.instance()
	items[p] = r
	
	r.set_color(colorID)
	
	if animate:
		var spaw_p = Vector2(p.x, -_create_items_y[p.x] - 1)
		r.position = grid2local(spaw_p)
		_create_items_y[p.x] += 1
		r.move(grid2local(p))
		_wait_queue.push_front(Waiter.new(r, 'finish_move'))
		STATE = STATES.WAIT
	else:
		r.position = grid2local(p)
	add_child(r)

func _on_move_item(p1,p2):
	var r = items[p1]
	items[p1] = null
	items[p2] = r
	r.move(p2*ITEM_SIZE)
	_wait_queue.push_front(Waiter.new(r, 'finish_move'))
	STATE = STATES.WAIT

func _swap_items(p1,p2):
	
	self.count_swaps += 1
	
	var i1 = items[p1]
	var i2 = items[p2]
	
	items[p1] = i2
	items[p2] = i1
	
	i1.move(p2*ITEM_SIZE)
	i2.move(p1*ITEM_SIZE)
	
	wait(i1, 'finish_move')
	wait(i2, 'finish_move')
	
	STATE = STATES.WAIT

func wait(obj, signal_name):
	_wait_queue.push_front(Waiter.new(obj, signal_name))
	STATE = STATES.WAIT

func _on_chain_remove(chain):
	for p in chain:
		if items[p]:
			var r = items[p]
			items[p] = null
			emit_signal("element_removed", r.frame)
			r.destroy()
			_wait_queue.push_front(Waiter.new(r, 'finish_destroy'))
			score += 1
	STATE = STATES.WAIT

var _start_p
var _finish_p

func _gui_input(event):
	match STATE:
		STATES.NONE:
			if (event is InputEventMouseButton
			and event.is_pressed()
			and event.button_index == BUTTON_LEFT
			and can_swap):
				var p = get_local_mouse_position()
				if click_rect.has_point(p):
					items[local2grid(p)].on_focus_enter()
					STATE = STATES.PRESSED
					_start_p = p
					get_tree().set_input_as_handled()
					_hint_timer = 0
		STATES.PRESSED:
			if (event is InputEventMouseButton
			and not event.is_pressed()
			and event.button_index == BUTTON_LEFT):
				_finish_p = get_local_mouse_position()
				_start_p = local2grid(_start_p)
				_finish_p = local2grid(_finish_p)
				items[_start_p].on_focus_exit()
				STATE = STATES.NONE
				var dir = _finish_p - _start_p
				
				if dir.length() != 0:
					
					if abs(dir.x) >= abs(dir.y):
						dir.y = 0
						dir.x = sign(dir.x)
					else:
						dir.x = 0
						dir.y = sign(dir.y)
						
					match_map.swap(_start_p,_start_p+dir)
				get_tree().set_input_as_handled()

# warning-ignore:unused_argument
func _process(delta):
	match STATE:
		STATES.NONE:
			_hint_timer += delta
			if _hint_timer >= HINT_TIMEOUT:
				if len(match_map.possible_swaps) > 0:
					var i = randi() % match_map.possible_swaps.size()
					var swap = match_map.possible_swaps[i]
					var p = swap[randi() % 2]
					items[p].hint()
				_hint_timer = 0
		STATES.UPDATE:
			match_map.update()
			if match_map.is_update_finished():
				STATE = STATES.NONE
				emit_signal("update_finished")
		STATES.WAIT:
			for i in range(_wait_queue.size()-1,-1,-1):
				if _wait_queue[i].finished:
					_wait_queue.remove(i)
			if _wait_queue.size() == 0:
				STATE = STATES.UPDATE
				for i in range(XCOUNT):
					_create_items_y[i] = 0

func local2grid(p):
	return (p/ITEM_SIZE).floor()

func grid2local(p):
	return p*ITEM_SIZE

func _draw():
	if STATE == STATES.HINT:
		for x in range(XCOUNT):
			for y in range(YCOUNT):
				draw_rect(Rect2(x*ITEM_SIZE, y*ITEM_SIZE, ITEM_SIZE-2*3, ITEM_SIZE-2*3), Color.gray)


