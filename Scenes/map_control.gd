extends Control

var levels = [
	
	"train1.tscn",
	"train2.tscn",
	"train3.tscn",
	"test1.tscn",
	"test4.tscn",
	"test2.tscn",
	"test5.tscn",
	"test3.tscn",
	"end.tscn"]

var current = null

func load_level():
	if get_child_count() > 0:
		get_child(0).queue_free()
	current = load("res://Scenes/LevelMap/"+levels.pop_front())
	var lvl = current.instance()
	add_child(lvl)
	global.main.connect_level(lvl)
	lvl.position = rect_size / 2 - Vector2(lvl.WIDTH+2, lvl.HEIGHT+2)*lvl.GLOBAL_CELL_SIZE / 2

func reset_level():
	if get_child_count() > 0:
		get_child(0).queue_free()
	var lvl = current.instance()
	add_child(lvl)
	lvl.position = rect_size / 2 - Vector2(lvl.WIDTH+2, lvl.HEIGHT+2)*lvl.GLOBAL_CELL_SIZE / 2
	global.main.connect_level(lvl)
	