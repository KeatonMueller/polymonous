extends StaticBody2D

var tw: Tween
var num_sides: int = 0		# must be overriden by child class
var radius: float = 0.0		# must be overriden by child class
var main: Node2D
var values: Dictionary = {}
var bases: Array = []

func _ready():
	main = get_parent()
	tw = get_node("Tween")

func set_values(thetas: Array):
	if bases.size() == 0:
		for i in range(num_sides):
			bases.append(get_node("Sprite" + str(i)))
	values = {}
	var pos_vals = range(num_sides)
	for i in range(num_sides):
		var theta = thetas[i + 1]
		var val = pos_vals[randi() % pos_vals.size()]
		pos_vals.erase(val)
		values[theta] = val
		bases[i].texture = load("res://Textures/BaseSpace/frame_" + str(val) + ".png")

func lock_fragment(theta: float, value: int):
	# find which index `theta` corresponds to
	var i = 0
	for th in values.keys():
		if th == theta:
			break
		i += 1
	# set the inner sprite to the `value` of the fragment
	var child: Sprite = bases[i].get_node("Sprite")
	child.texture = load("res://Textures/BaseSpace/inner_" + str(value) + ".png")
	# modulate from transparent to opaque
	var color = Color(child.modulate)
	color.a = 1
	var _d = tw.interpolate_property(
		child,
		"modulate",
		child.modulate,
		color,
		0.125,
		Tween.TRANS_LINEAR
	)
	_d = tw.start()
