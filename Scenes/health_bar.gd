extends HBoxContainer

var HealthPoint = preload("health_point.tscn")

func _on_health_change(h):
	if h < 0:
		return
	while get_child_count() > h:
		var n = get_child(get_child_count()-1)
		remove_child(n)
		n.queue_free()
	while get_child_count() < h:
		var n = HealthPoint.instance()
		add_child(n)