extends Control

onready var map = $VBoxContainer/Control2/map_control/map
onready var player = map.get_node("player")
onready var matchControl = $VBoxContainer/Control/matchControl

func _ready():
	matchControl.match_map.connect("swap", self, "_on_swap")
	map.connect("player_turn", matchControl, "set_can_swap", [true])
	player.connect("exited", self, "restart")
	
func _on_swap(p1,p2):
	var dir = p2 - p1
	matchControl.can_swap = false
	player.input_swap(map, dir)

func restart():
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()
