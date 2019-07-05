extends "res://Scenes/Unit.gd"

const MELEE_ATTACK_TIME = 0.5

var health = 1 setget set_health

func set_health(h):
	health = h
	if health <= 0:
		emit_signal("dead")
		STATE = DEAD
		_timer = DEAD_TIME
# warning-ignore:return_value_discarded
		$hit_effect.connect("finished", self, "queue_free")


# warning-ignore:unused_class_variable
var _name = "Slime"

# warning-ignore:unused_class_variable
var pwr_values = [0,1,0,0]

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
			dead_fade_out(delta)

onready var _last_turn = Vector2(sign(scale.x), 0)

func turn(map):
	var possible_moves = [Vector2(-1, 0), Vector2(1, 0)] 
	var possible_attacks = []
	for i in range(len(possible_moves)-1, -1, -1):
		var target_pos = map_pos + possible_moves[i]
		if not (map.is_in_room(target_pos) and map.is_free(target_pos) and map.is_wall(target_pos+Vector2.DOWN)):
			possible_moves.remove(i)
		if map.get(target_pos) == map.player:
			possible_attacks.append(target_pos - map_pos)
	
	if not is_on_floor():
		possible_moves = []
		_last_turn = Vector2.DOWN
	
	if len(possible_attacks) > 0:
		_last_turn = possible_attacks[0]
		input_swap(map, possible_attacks[0])
	elif len(possible_moves) == 0:
		input_swap(map, _last_turn)
	else:
		if _last_turn in possible_moves:
			input_swap(map, _last_turn)
		else:
			var i = randi() % len(possible_moves)
			_last_turn = possible_moves[i]
			input_swap(map, possible_moves[i])
	
var y_velocity = 0
const JUMP_SPEED = 0.5

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
	
	
	if not (map.is_free(new_pos)):
		new_pos = map_pos
	
	if y_velocity != 0:
		new_pos.y += sign(y_velocity)
		
		if not (map.is_free(new_pos)):
			if map.is_wall(new_pos):
				new_pos.y = map_pos.y
			else:
				new_pos.x = map_pos.x
				
				if not (map.is_free(new_pos)):
					new_pos.y = map_pos.y
	
	var attack_pos = dir+map_pos
	if map.can_attack(self, attack_pos):
		attack(map.get(attack_pos))
	elif map.get(attack_pos):
		pass
#		show_my_weakness(map.get(attack_pos))
	
	if new_pos != map_pos:
		map.move(self, new_pos)
	
	map.next()

func get_damage(dmg, attacker):
	self.health -= dmg
	$hit_effect.play(map_pos - attacker.map_pos)
	global.map.wait($hit_effect, "finished")
	

func attack(obj):
	obj.get_damage(1, self)
	var d = obj.map_pos - map_pos
	if abs(d.x) > 0:
		scale.x = sign(d.x)

func can_attack(obj):
	if obj.is_in_group("slime"):
		return false
	else:
		return true