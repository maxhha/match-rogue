extends Control

func load_level():
	var lvl = $map
	global.main.connect_level(lvl)
	lvl.position = rect_size / 2 - Vector2(lvl.WIDTH+2, lvl.HEIGHT+2)*lvl.GLOBAL_CELL_SIZE / 2