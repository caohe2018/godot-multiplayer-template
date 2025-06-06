extends Node2D

var color : set = set_color

func _network_ready(is_source):
	if is_source:
		set_color(Color.from_hsv(randf_range(1, 360), 1, 1))
		position = Vector2(randf_range(0, 600), randf_range(0, 400))
	# same value on all clients now!
	print(color)

func set_color(c: Color):
	color = c
	$token.color = c
