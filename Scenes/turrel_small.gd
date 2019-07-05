extends AnimatedSprite

var map_pos = Vector2()

export (int) var reload_timeout = 2
export (int) var time = 0

var shoot_dir = Vector2(1,0)
# warning-ignore:unused_signal
signal dead

func _ready():
	if time >= reload_timeout - 1:
		play('reload')
		frame = frames.get_frame_count('reload')-1
	shoot_dir = Vector2(1,0).rotated(rotation)
	if abs(shoot_dir.x) > abs(shoot_dir.y):
		shoot_dir = Vector2(1,0)*sign(shoot_dir.x)
	else:
		shoot_dir = Vector2(0,1)*sign(shoot_dir.y)
	global.clever_rotate(self, shoot_dir)

var Arrow = preload("res://Scenes/arrow.tscn")

func turn(map):
	
	time += 1
	if time >= reload_timeout:
		play('shoot')
		var a = Arrow.instance()
		a.set_dir(shoot_dir)
		map.add_item(a, map_pos)
		a.position += map.CELL_SIZE * shoot_dir
		time = 0
	elif time >= reload_timeout - 1:
		play('reload')
	map.next()