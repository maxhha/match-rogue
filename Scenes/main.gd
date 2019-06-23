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
	
	if map.is_in_room(player.map_pos+dir):
		map.move(player, player.map_pos+dir)
	else:
		map.next()