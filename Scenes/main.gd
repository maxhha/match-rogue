extends Control

const BUF_LEN = 5
const COUNT_TYPES = 4

var _values_coefs = []
var _calculated_values = []
var _values_queue = []

var _current_values = []

onready var map = $VBoxContainer/Control2/map_control/map
onready var player = map.get_node("player")
onready var matchControl = $VBoxContainer/Control/matchControl

signal push_value(type, value)
signal update_values(values)

func _ready():
	_values_coefs = [1, 0.5, 0.25, 0.12, 0.06]
	_calculated_values = [0,0,0,0]
	_current_values = [0,0,0,0]
	for i in range(COUNT_TYPES):
		_values_queue.append([])
	
	assert(_values_coefs.size() == BUF_LEN)
	assert(_calculated_values.size() == COUNT_TYPES)
	assert(_current_values.size() == COUNT_TYPES)
	
	$VBoxContainer/Control3/accordion/values/table.update_coefs(_values_coefs)
	
	# Player input connect
	matchControl.match_map.connect("swap", self, "_on_swap")
	map.connect("player_turn", matchControl, "set_can_swap", [true])
	player.connect("exited", self, "restart")
	
	# Values calculator connect
	matchControl.connect("element_removed", self, "_on_element_removed")
	matchControl.connect("update_finished", self, "_on_update_finished")

func _on_swap(p1,p2):
	var dir = p2 - p1
	matchControl.can_swap = false
	player.input_swap(map, dir)

func restart():
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()

func _on_element_removed(type):
	_current_values[type] += 1

func _on_update_finished():
	for t in range(COUNT_TYPES):
		if _values_queue[t].size() >= BUF_LEN:
			_values_queue[t].pop_back()
		_values_queue[t].push_front(_current_values[t])
		emit_signal("push_value", t, _current_values[t])
		var s = 0
		for i in range(_values_queue[t].size()):
			s += _values_queue[t][i]*_values_coefs[i]
		_calculated_values[t] = s
		_current_values[t] = 0
	emit_signal("update_values", _calculated_values)
		