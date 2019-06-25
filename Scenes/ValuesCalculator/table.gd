extends VBoxContainer

var Coef = preload("coef.tscn")
var coefs = []



func update_coefs(coefs):
	self.coefs = coefs
	for n in $coefs.get_children():
		$coefs.remove_child(n)
		n.queue_free()
	for i in range(coefs.size()):
		var n = Coef.instance()
		n.text = "%d%%" % (coefs[i]*100)
		$coefs.add_child(n)


func _on_main_push_value(type, value):
	get_node("count"+str(type)).push(value)