extends AnimatedSprite

var hidden = true
var activated = false
var map_pos

# warning-ignore:unused_signal
signal dead

func enter(u):
	if not u.is_in_group("slime"):
		if not hidden:
			var time = 0.2
			if u.map_pos.y < map_pos.y:
				time += 0.15
			var timer = get_tree().create_timer(time)
			timer.connect("timeout", u, "get_damage", [1, self])
		
func turn(map):
	var u = map.get(map_pos)
	
	if activated:
		if hidden:
			hidden = false
			play('up')
		if u:
			if not u.is_in_group("slime"):
				u.get_damage(1, self)
		else:
			activated = false
	elif u:
		activated = true
	elif not hidden:
		play('down')
		hidden = true
	map.next()