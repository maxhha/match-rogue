extends AnimatedSprite

const MOVE_SPEED = 40
const DEAD_TIME = 0.3

enum {NONE, MOVE, DEAD}
var STATE = NONE

# warning-ignore:unused_class_variable
var map_pos = Vector2()

var pwr_values = [0,0,0,0]

var _target
var _timer

signal move_finished
signal dead
# warning-ignore:unused_signal
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
				if d.y < 0:
					play("jump_up")
				position += MOVE_SPEED * delta * d.normalized()
				if abs(d.x) > 0:
					scale.x = sign(d.x)
		NONE:
			if is_on_floor():
				play("idle")
			else:
				play("jump_"+("down" if y_velocity > -1 else "up"))
		DEAD:
			if _timer > 0:
				_timer -= delta
				self_modulate.a = _timer/DEAD_TIME
const JUMP_SPEED = 1
var y_velocity = 0

func input_swap(map, dir : Vector2):
	dir = dir.floor()
	var new_pos = map_pos
	
	#update gravity
	if not is_on_floor():
		y_velocity += 1
	else:
		y_velocity = 0
	
	#first make input action
	match dir:
		Vector2.LEFT, Vector2.RIGHT:
			new_pos += dir
		Vector2.UP:
			if is_on_floor():
				y_velocity = -JUMP_SPEED
		Vector2.DOWN:
			if not is_on_floor():
				if y_velocity < 1:
					y_velocity = 1
				
				# move to bottom
#				var next = new_pos 
#				while map.is_free(Vector2.DOWN+next) and  map.is_in_room(Vector2.DOWN+next):
#					next.y += 1
#				y_velocity = 0
#				new_pos = next
	
	
	if not (map.is_free(new_pos) or map.is_exit(new_pos)):
		new_pos = map_pos
	
	if y_velocity != 0:
		new_pos.y += sign(y_velocity)
		
		if not (map.is_free(new_pos) or map.is_exit(new_pos)):
			if map.is_wall(new_pos):
				new_pos.y = map_pos.y
			else:
				new_pos.x = map_pos.x
				
				if not (map.is_free(new_pos) or map.is_exit(new_pos)):
					new_pos.y = map_pos.y
	
	var attack_pos = dir+map_pos
	if map.can_attack(self, attack_pos):
		attack(map.get(attack_pos))
	elif map.get(attack_pos):
		show_my_weakness(map.get(attack_pos))
	
	if new_pos != map_pos:
		if map.is_exit(new_pos):
			map.move(self, new_pos+Vector2.RIGHT)
# warning-ignore:return_value_discarded
			connect("move_finished", self, "emit_signal", ["exited"], CONNECT_ONESHOT | CONNECT_DEFERRED)
		else:
			map.move(self, new_pos)
	
	map.next()
	
#	# this movement code support diagonal move,
#	# even if there is a horizontal obstacle
#	if is_on_floor():
#		y_velocity = 0
#		match dir:
#			Vector2.LEFT, Vector2.RIGHT:
#				var next_pos = dir + map_pos
#				if map.is_in_room(next_pos) and map.is_free(next_pos):
#					map.move(self, next_pos)
#				elif map.is_exit(next_pos):
#					map.move(self, next_pos+dir)
## warning-ignore:return_value_discarded
#					connect("move_finished", self, "emit_signal", ["exited"], CONNECT_ONESHOT | CONNECT_DEFERRED)
#			Vector2.UP:
#				var next_pos = dir + map_pos
#				if map.is_in_room(next_pos) and map.is_free(next_pos):
#					map.move(self, next_pos)
#				y_velocity = JUMP_SPEED
#	else:
#		y_velocity += 1
#		var next_pos =Vector2.DOWN*sign(y_velocity) + map_pos
#		match dir:
#			Vector2.LEFT, Vector2.RIGHT:
#				var can_move = true
#				if sign(y_velocity):
#					can_move = (
#						map.is_free(Vector2(next_pos.x+dir.x, map_pos.y))
#						or map.is_free(Vector2(map_pos.x, next_pos.y))
#					)
#				if can_move and map.is_free(next_pos+dir):
#					next_pos += dir
#			Vector2.DOWN:
#				if y_velocity < 0:
#					y_velocity = 0
#				while map.is_free(Vector2.DOWN+next_pos) and  map.is_in_room(Vector2.DOWN+next_pos):
#					next_pos.y += 1
#
#		if map.is_in_room(next_pos) and map.is_free(next_pos):
#			map.move(self, next_pos)
#		elif map.is_exit(next_pos):
#			map.move(self, next_pos+dir)
## warning-ignore:return_value_discarded
#			connect("move_finished", self, "emit_signal", ["exited"], CONNECT_ONESHOT | CONNECT_DEFERRED)
#	map.next()
	

func is_on_floor():
	var under = map_pos + Vector2.DOWN
	return global.map.is_wall(under)

func _on_update_power_values(values):
	pwr_values = values

func attack(obj):
	if can_attack(obj):
		obj.get_damage(1, self)
		var d = obj.map_pos - map_pos
		if abs(d.x) > 0:
			scale.x = sign(d.x)
		

func can_attack(obj):
	for i in range(pwr_values.size()):
		if int(pwr_values[i]) < int(obj.pwr_values[i]):
			return false
	return true

var health = 1 setget set_health
signal health_changed(new_val)

func set_health(h):
	health = h
	emit_signal("health_changed", h)
	if health <= 0:
		emit_signal("dead")
		STATE = DEAD
		_timer = DEAD_TIME
		$hit_effect.connect("finished", self, "queue_free")

# warning-ignore:unused_argument
func get_damage(dmg, attacker):
	$hit_effect.play(map_pos - attacker.map_pos)
	global.map.wait($hit_effect, "finished")
	self.health -= dmg

var WeaknessPWR = preload("res://Scenes/less_pwr.tscn")

func show_my_weakness(obj):
	var x = obj.global_position.x
	var y = obj.global_position.y - global.map.GLOBAL_CELL_SIZE/4
	for i in range(pwr_values.size()):
		if int(pwr_values[i]) < int(obj.pwr_values[i]):
			var n = WeaknessPWR.instance()
			n.set_type(i)
			global.map.add_child(n)
			n.set_pos(Vector2(x, y))
			y -= n.HEIGHT