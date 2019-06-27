extends AnimatedSprite

const MOVE_SPEED = 40
const MELEE_ATTACK_TIME = 0.5
const DEAD_TIME = 0.3

enum {NONE, MOVE, DEAD}
var STATE = NONE

var health = 1 setget set_health
var _name = "Slime"

signal dead

func set_health(h):
	health = h
	if health <= 0:
		emit_signal("dead")
		STATE = DEAD
		_timer = DEAD_TIME
		$hit_effect.connect("finished", self, "queue_free")

# warning-ignore:unused_class_variable
var map_pos = Vector2()

var pwr_values = [0,1,0,0]

var _target
var _timer

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
				if abs(d.x) > 0:
					scale.x = sign(d.x)
		DEAD:
			if _timer > 0:
				_timer -= delta
				self_modulate.a = _timer/DEAD_TIME

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

func get_damage(dmg, attacker):
	self.health -= dmg
	$hit_effect.play(map_pos - attacker.map_pos)
	get_parent().wait($hit_effect, "finished")
	

func attack(obj):
	obj.get_damage(1, self)
	var d = obj.map_pos - map_pos
	if abs(d.x) > 0:
		scale.x = sign(d.x)
		