extends Sprite

var map_pos

func enter(u):
	if not u.is_in_group("slime"):
		var time = 0.2
		if u.map_pos.y < map_pos.y:
			time += 0.15
		var timer = get_tree().create_timer(time)
		timer.connect("timeout", u, "get_damage", [1, self])
