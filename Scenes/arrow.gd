extends "res://Scenes/Unit.gd"

const SPEED = 2 # in cells

var dir = Vector2() setget set_dir

func _process(delta):
	match STATE:
		MOVE:
			play("fly")
			var d = _target - position
			if d.length() <= MOVE_SPEED*delta:
				position = _target
				STATE = NONE
				emit_signal("move_finished")
			else:
				position += MOVE_SPEED * delta * d.normalized()
		NONE:
			if animation != "die":
				play("idle")
		DEAD:
			if _timer > 0:
				_timer -= delta
				self_modulate.a = _timer/DEAD_TIME
			else:
				queue_free()

func set_dir(d):
	dir = d
	global.clever_rotate(self, dir)

func turn(map):
	var new_pos = map_pos
	var distance = SPEED
	
	while distance > 0:
		var p = new_pos + dir
		if map.is_free(p): # if next cell is empty
			new_pos = p # move 
			distance -= 1
		else: 
			emit_signal('dead') # destroy
			if new_pos != map_pos:
				move(map.grid2local(new_pos))
# warning-ignore:return_value_discarded
				connect("move_finished", self, "play", ["die"])
# warning-ignore:return_value_discarded
				connect("move_finished", self, "connect", ["animation_finished", self, "start_dead"], CONNECT_DEFERRED)
				map.wait(self, "move_finished")
			else:
				play('die')
# warning-ignore:return_value_discarded
				connect("animation_finished", self, "start_dead", [], CONNECT_DEFERRED)
			break
	if distance == 0:
		move(map.grid2local(new_pos))
		map_pos = new_pos
		map.wait(self, "move_finished")
	
	map.next()

func start_dead():
	STATE = DEAD
	_timer = DEAD_TIME