extends Node2D

# warning-ignore:unused_class_variable
var map
# warning-ignore:unused_class_variable
var main

const TYPE2ICON = {
	0: preload("res://Sprites/item0_icon.png"),
	1: preload("res://Sprites/item1_icon.png"),
	2: preload("res://Sprites/item2_icon.png"),
	3: preload("res://Sprites/item3_icon.png")
}

func clever_rotate(obj, dir):
	match dir:
		Vector2.RIGHT:
			obj.flip_h = false
			obj.flip_v = false
			obj.rotation = 0
		Vector2.LEFT:
			obj.flip_h = false
			obj.flip_v = true
			obj.rotation = PI
		Vector2.UP:
			obj.flip_h = false
			obj.flip_v = true
			obj.rotation = -PI/2
		Vector2.DOWN:
			obj.flip_h = false
			obj.flip_v = false
			obj.rotation = PI/2