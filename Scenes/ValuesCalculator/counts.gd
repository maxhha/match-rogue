extends Control

const BUF_LEN = 5
const SIZE = 64

var Numb = preload("numb.tscn")

var queue = []

func push(n):
	if len(queue) >= BUF_LEN:
		queue.pop_back().queue_free()
	var node = Numb.instance()
	node.text = str(n)
	node.rect_position.y = 3
	add_child(node)
	queue.push_front(node)
	for i in range(len(queue)):
		queue[i].rect_position.x = i * SIZE