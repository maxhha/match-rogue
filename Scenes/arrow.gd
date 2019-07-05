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
			var finish_signal = "dead"
			
			if new_pos != map_pos:
				finish_signal = "move_finished"
				move(map.grid2local(new_pos))
				map.wait(self, "move_finished")
			
			if map.is_wall(p):
# warning-ignore:return_value_discarded
				connect(finish_signal, self, "play", ["die"])
# warning-ignore:return_value_discarded
				connect(finish_signal, self, "connect",
					["animation_finished", self, "start_dead"],
					CONNECT_DEFERRED)
			else:
				var u = map.get(p)
				if u:
# warning-ignore:return_value_discarded
					connect(finish_signal, u, 
						"get_damage", [1, self],
						CONNECT_ONESHOT)
# warning-ignore:return_value_discarded
				connect(finish_signal, self,
					"move", [map.grid2local(p) - map.CELL_SIZE*dir*0.5],
					CONNECT_ONESHOT)
# warning-ignore:return_value_discarded
				connect(finish_signal, self, "connect",
					["move_finished", self, "queue_free"],
					CONNECT_DEFERRED | CONNECT_ONESHOT)
			
			emit_signal('dead')
			break

			
	if distance == 0:
		move(map.grid2local(new_pos))
		map_pos = new_pos
		map.wait(self, "move_finished")
	
	map.next()


func start_dead():
	STATE = DEAD
	_timer = DEAD_TIME