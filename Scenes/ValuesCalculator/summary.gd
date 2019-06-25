extends VBoxContainer

export (PoolColorArray) var Colors = []

func _on_main_update_values(values):
	for t in range(values.size()):
		var n = get_node("numb"+str(t)+"/lbl")
		n.text = "%d" % values[t]
		if values[t] >= 1:
			n.modulate = Colors[t]
		else:
			n.modulate = Color.white
		