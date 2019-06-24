extends Control

onready var map = $VBoxContainer/Control2/map_control/map
onready var player = map.get_node("player")
onready var matchControl = $VBoxContainer/Control/matchControl

func _ready():
	matchControl.match_map.connect("swap", self, "_on_swap")
	map.connect("player_turn", matchControl, "set_can_swap", [true])
	
func _on_swap(p1,p2):
	var dir = p2 - p1
	matchControl.can_swap = false
	var next_pos = player.map_pos+dir
	
	if map.is_in_room(next_pos):
		map.move(player, next_pos)
	elif map.is_exit(next_pos):
		map.move(player, next_pos)
		map.player.connect("move_finished", self, "restart")
	
	map.next()

func restart():
	get_tree().reload_current_scene()
