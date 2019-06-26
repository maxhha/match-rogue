extends PanelContainer

const TYPE2TEXTURE = {
	0: preload("res://Sprites/item0_icon.png"),
	1: preload("res://Sprites/item1_icon.png"),
	2: preload("res://Sprites/item2_icon.png"),
	3: preload("res://Sprites/item3_icon.png")
}

func set_name(s):
	$body/name.text = s

var Prop = preload("prop.tscn")

func add_pwr_value(type, val):
	add_prop(type, val)

func add_prop(type, value):
	var n = Prop.instance()
	n.get_node("icon").texture = TYPE2TEXTURE[type]
	n.get_node("lbl").text = str(value)
	$body.add_child(n)
	$body/offset.raise()

func popup(pos):
	modulate.a = 0
	show()
	var half_w = rect_size.x / 2
	pos.x = clamp(pos.x, half_w, get_parent().rect_size.x - half_w)
	rect_global_position = pos + Vector2(-half_w, 0)
	modulate.a = 1
	

func _input(event):
	if visible and event is InputEventMouseButton and event.is_pressed():
		fade_out()
		get_tree().set_input_as_handled()

func fade_out():
	hide()

func clear():
	for i in $body.get_children():
		if not i.name in ["offset", "name"]:
			$body.remove_child(i)
			i.queue_free()
	rect_size = Vector2.ZERO