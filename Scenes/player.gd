extends Sprite

const MOVE_SPEED = 40

enum {NONE, MOVE}
var STATE = NONE

# warning-ignore:unused_class_variable
var map_pos = Vector2()

var _target

signal move_finished
signal exited

func move(p):
	_target = p
	STATE = MOVE

func _process(delta):
	match STATE:
		MOVE:
			var d = _target - position
			var wall_border_size = 1
			var center_x = (global.map.WIDTH + wall_border_size*2)*global.map.CELL_SIZE / 2
			self_modulate.a = clamp((center_x-abs(position.x - center_x))/global.map.CELL_SIZE,0,1)
			if d.length() <= MOVE_SPEED*delta:
				position = _target
				STATE = NONE
				emit_signal("move_finished")
			else:
				position += MOVE_SPEED * delta * d.normalized()

const JUMP_SPEED = -1
var y_velocity = 0

func input_swap(map, dir : Vector2):
	dir = dir.floor()
	
	if is_on_floor():
		y_velocity = 0
		match dir:
			Vector2.LEFT, Vector2.RIGHT:
				var next_pos = dir + map_pos
				if map.is_in_room(next_pos) and map.is_free(next_pos):
					map.move(self, next_pos)
				elif map.is_exit(next_pos):
					map.move(self, next_pos+dir)
					connect("move_finished", self, "emit_signal", ["exited"], CONNECT_ONESHOT | CONNECT_DEFERRED)
			Vector2.UP:
				var next_pos = dir + map_pos
				if map.is_in_room(next_pos) and map.is_free(next_pos):
					map.move(self, next_pos)
				y_velocity = JUMP_SPEED
	else:
		y_velocity += 1
		var next_pos =Vector2.DOWN*sign(y_velocity) + map_pos
		match dir:
			Vector2.LEFT, Vector2.RIGHT:
				var can_move = true
				if sign(y_velocity):
					can_move = (
						map.is_free(Vector2(next_pos.x+dir.x, map_pos.y))
						or map.is_free(Vector2(map_pos.x, next_pos.y))
					)
				if can_move and map.is_free(next_pos+dir):
					next_pos += dir
			Vector2.DOWN:
				if y_velocity < 0:
					y_velocity = 0
				while map.is_free(Vector2.DOWN+next_pos) and  map.is_in_room(Vector2.DOWN+next_pos):
					next_pos.y += 1
	
		if map.is_in_room(next_pos) and map.is_free(next_pos):
			map.move(self, next_pos)
		elif map.is_exit(next_pos):
			map.move(self, next_pos+dir)
			connect("move_finished", self, "emit_signal", ["exited"], CONNECT_ONESHOT | CONNECT_DEFERRED)
	map.next()

func is_on_floor():
	var under = map_pos + Vector2.DOWN
	return not global.map.is_in_room(under)