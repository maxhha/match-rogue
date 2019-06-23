class Cell:
	var type = null setget set_type
	var wall = false
	
	func _init(t):
		type = t
	
	func set_type(t):
		if not wall:
			type = t

class T:
	#var _klass
	var id
	#var floating = false
	var can_swap = true
	var _mask = []
	var _layer = []
	
	var prob = 0 setget set_prob
	
	signal change_prob(last, new)
	
	func set_prob(p):
		emit_signal("change_prob", prob, p)
		prob = p
	
	func _init(id, prob, layer=1, mask=null, can_swap=true):
		
		self.id = id
		self.prob = prob
		self.can_swap = can_swap
		if mask == null:
			mask = layer
		
		if typeof(layer) == TYPE_INT:
			_layer = PoolIntArray([layer])
		else:
			_layer = PoolIntArray(layer)
		
		if typeof(mask) == TYPE_INT:
			_mask = PoolIntArray([mask])
		else:
			_mask = PoolIntArray(mask)
	
	func equals(t):
		for i in range(min(_mask.size(), t._layer.size())):
			if _mask[i] & t._layer[i] > 0:
				return true
		
		for i in range(min(_layer.size(), t._mask.size())):
			if _layer[i] & t._mask[i] > 0:
				return true
		
		return false

var ZERO_TYPE = T.new('null_type', 0, 0, 0, false)

var HEIGHT
var WIDTH
var RECOMB_PROB = 0.2

var field = []
var _types = []
var _types_sum = 0

var possible_swaps = []

signal create_item(pos, id)
signal move_item(start, finish)
signal swap(pos1, pos2)
signal remove_chain(poses)

func _init(w, h, types=[]):
	WIDTH = w
	HEIGHT = h
	for x in range(w):
		field.append([])
# warning-ignore:unused_variable
		for y in range(h):
			field[x].append(null)
	_types = types
	_types_sum = 0
	for t in types:
		_types_sum += t.prob
		t.connect("change_prob", self, "_on_change_prob")

func add_type(t):
	_types_sum += t.prob
	t.connect("change_prob", self, "_on_change_prob")
	_types.append(t)

func set_id_prob(id, prob):
	for i in _types:
		if i.id == id:
			i.prob = prob
			return

func _on_change_prob(l,n):
	_types_sum += n - l

func create_cells():
	for x in range(WIDTH):
		for y in range(HEIGHT):
			field[x][y] = Cell.new(ZERO_TYPE)
			

func get_random_type():
	var s = randi() % _types_sum
	for t in _types:
		if t.prob > s:
			return t
		else:
			s -= t.prob

func fill_random():
	for y in range(2):
		field[0][y].type = get_random_type()
		field[1][y].type = get_random_type()
		
		for x in range(2, WIDTH):
			field[x][y].type = get_random_type()
			while field[x-2][y].type.equals(field[x-1][y].type) and field[x][y].type.equals(field[x-1][y].type):
				field[x][y].type = get_random_type()
	
	
	for y in range(2, HEIGHT):
		
		for x in range(2):
			field[x][y].type = get_random_type()
			
			while field[x][y-2].type.equals(field[x][y-1].type) and field[x][y-1].type.equals(field[x][y].type):
				field[x][y].type = get_random_type()
		
		for x in range(2, WIDTH):
			field[x][y].type = get_random_type()
			while (field[x-2][y].type.equals(field[x-1][y].type) and field[x][y].type.equals(field[x-1][y].type) or
				field[x][y-2].type.equals(field[x][y-1].type) and field[x][y-1].type.equals(field[x][y].type)):
				field[x][y].type = get_random_type()

func detect_possible_swaps():
	var set = []
	for x in range(WIDTH):
		for y in range(HEIGHT):
			if not field[x][y].type.can_swap:
				continue
			if x < WIDTH - 1 and field[x+1][y].type.can_swap:
				var t = field[x][y]
				field[x][y] = field[x+1][y]
				field[x+1][y] = t
				
				if has_chain_at(x, y) or has_chain_at(x+1, y):
					set.append([Vector2(x,y), Vector2(x+1, y)])
					
				t = field[x][y]
				field[x][y] = field[x+1][y]
				field[x+1][y] = t
			
			if y < HEIGHT - 1 and field[x][y+1].type.can_swap:
				var t = field[x][y]
				field[x][y] = field[x][y+1]
				field[x][y+1] = t
				
				if has_chain_at(x, y) or has_chain_at(x, y+1):
					set.append([Vector2(x,y), Vector2(x, y+1)])
					
				t = field[x][y]
				field[x][y] = field[x][y+1]
				field[x][y+1] = t
	possible_swaps = set
	
	return len(set) > 0

func has_chain_at(x,y):
	if field[x][y].type == ZERO_TYPE:
		return false
	
	var t0 = field[x][y].type
	var hlen = 1
	var vlen = 1
	
	var t = t0
	var i = x - 1
	while i >= 0 and t.equals(field[i][y].type):
		t = field[i][y].type
		i -= 1
		hlen += 1
	
	t = t0
	i = x + 1
	while i < WIDTH and t.equals(field[i][y].type):
		t = field[i][y].type
		i += 1
		hlen += 1
	
	t = t0
	i = y - 1
	while i >= 0 and t.equals(field[x][i].type):
		t = field[x][i].type
		i -= 1
		vlen += 1
	
	t = t0
	i = y + 1
	while i < HEIGHT and t.equals(field[x][i].type):
		t = field[x][i].type
		i += 1
		vlen += 1
	
	return hlen >= 3 or vlen >= 3

func remove_chains_at(poses):
	
	var set_chains = []
	
	for p in poses:
		var x = p.x
		var y = p.y
		
		var t0 = field[x][y].type
		
		if t0 == ZERO_TYPE:
			continue
		
		var hchain = [Vector2(x,y)]
		var vchain = [Vector2(x,y)]
		
		var t = t0
		var i = x - 1
		while i >= 0 and t.equals(field[i][y].type):
			t = field[i][y].type
			hchain.append(Vector2(i,y))
			i -= 1
		
		t = t0
		i = x + 1
		while i < WIDTH and t.equals(field[i][y].type):
			t = field[i][y].type
			hchain.append(Vector2(i,y))
			i += 1
		
		t = t0
		i = y - 1
		while i >= 0 and t.equals(field[x][i].type):
			t = field[x][i].type
			vchain.append(Vector2(x,i))
			i -= 1
		
		t = t0
		i = y + 1
		while i < HEIGHT and t.equals(field[x][i].type):
			t = field[x][i].type
			vchain.append(Vector2(x,i))
			i += 1
		
		
		for c in [hchain, vchain]:
			
			if len(c) < 3:
				continue
			
			var chain_start = Vector2(x, y)
			var chain_end = Vector2(x, y)
			
			for pos in c:
				chain_start.x = min(chain_start.x, pos.x)
				chain_start.y = min(chain_start.y, pos.y)
				chain_end.x = max(chain_end.x, pos.x)
				chain_end.y = max(chain_end.y, pos.y)
			
			var unic = true
			for c in set_chains:
				if c[0] == chain_start and c[1] == chain_end:
					unic = false
					break
			
			if unic:
				set_chains.append([chain_start, chain_end])
	var all_c = []
	var c = []
	for chain in set_chains:
		for x in range(chain[0].x, chain[1].x+1):
			for y in range(chain[0].y, chain[1].y+1):
				c.append(Vector2(x,y))
		emit_signal("remove_chain", c)
		all_c += c
		c.clear()
	
	for p in all_c:
		field[p.x][p.y].type = ZERO_TYPE
	
	return set_chains.size() > 0

func get_type_at(p):
	if field[p.x][p.y].type:
		return field[p.x][p.y].type.id
	else:
		return null


var _to_check = []
var _state = 1
var _update_finished = true

func update():#return true when no update
	_update_finished = false
	match _state:
		0:#move items
			for x in range(WIDTH):
				var ny = HEIGHT - 1
				for y in range(ny, -1, -1):
					if field[x][y].wall or field[x][y].type != ZERO_TYPE:
						if ny != y and not field[x][y].wall:
							emit_signal("move_item", Vector2(x, y), Vector2(x, ny))
							field[x][ny].type = field[x][y].type
							field[x][y].type = ZERO_TYPE
							_to_check.append(Vector2(x, ny))
						ny -= 1
			if _to_check.size() == 0:
				_state = 2
			else:
				_state = 1
		1:#remove new chains
			if remove_chains_at(_to_check):
				_state = 0
			else:
				_state = 2
			_to_check.clear()
		2:#create new items
			for x in range(WIDTH):
				for y in range(HEIGHT-1, -1, -1):
					if not field[x][y].wall and field[x][y].type == ZERO_TYPE:
						field[x][y].type = get_random_type()
						if randf() >= RECOMB_PROB:
							while has_chain_at(x, y):
								field[x][y].type = get_random_type()
						emit_signal("create_item", Vector2(x, y), field[x][y].type.id)
						_to_check.append(Vector2(x,y))
			
			if _to_check.size() == 0:
				_state = 1
				detect_possible_swaps()
				_update_finished = true
			else:
				_state = 1

func is_update_finished():
	return _update_finished

func can_swap(p1,p2):
	p1 = p1.floor()
	p2 = p2.floor()
	for s in possible_swaps:
		if (s[0] == p1 and s[1] == p2) or (s[0] == p2 and s[1] == p1):
			return true
	return false

func swap(p1,p2):
	p1 = p1.floor()
	p2 = p2.floor()
	
	for s in possible_swaps:
		if (s[0] == p1 and s[1] == p2) or (s[0] == p2 and s[1] == p1):
			emit_signal("swap", p1, p2)
			var t = field[p1.x][p1.y].type
			field[p1.x][p1.y].type = field[p2.x][p2.y].type
			field[p2.x][p2.y].type = t
			_to_check.append(p1)
			_to_check.append(p2)
			return true
	
	return false