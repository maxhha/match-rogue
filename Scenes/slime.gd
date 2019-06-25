extends AnimatedSprite

const MOVE_SPEED = 40
const MELEE_ATTACK_TIME = 0.5

enum {NONE, MOVE}
var STATE = NONE

var health = 1 setget set_health

signal dead

func set_health(h):
	health = h
	if health <= 0:
		emit_signal("dead")
		queue_free()

# warning-ignore:unused_class_variable
var map_pos = Vector2()

var pwr_values = [0,1,0,0]

var _start
var _finish
var _target
var _timer

signal move_finished
signal attack_finished

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
				if abs(d.x) > 0:
					scale.x = sign(d.x)

func turn(map):
	var possible_moves = [Vector2(-1, 0), Vector2(1, 0)]
	var possible_attacks = []
	for i in range(len(possible_moves)-1, -1, -1):
		var target_pos = map_pos + possible_moves[i]
		if not (map.is_in_room(target_pos) and map.is_free(target_pos)):
			possible_moves.remove(i)
		if map.get(target_pos) == map.player:
			possible_attacks.append(target_pos)
	if len(possible_attacks) > 0:
		attack(map.get(possible_attacks[0]))
		map.next()
	elif len(possible_moves) == 0:
		map.next()
	else:
		var i = randi() % len(possible_moves)
		map.move(self, possible_moves[i] + map_pos)
		map.next()

func get_damage(dmg):
	self.health -= dmg

func attack(obj):
	obj.get_damage(1)
	var d = obj.map_pos - map_pos
	if abs(d.x) > 0:
		scale.x = sign(d.x)
		