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
		bases[i].texture = load("res://Textures/BaseSpace/sprite_" + str(val) + "_i.png")
		bases[i].get_node("Sprite").texture = load("res://Textures/BaseSpace/sprite_" + str(val) + ".png")

func lock_fragment(theta: float):
	var i = 0
	for th in values.keys():
		if th == theta:
			break
		i += 1
	var child: Sprite = bases[i].get_node("Sprite")
	var c_1 = Color(child.modulate)
	c_1.a = 1
	var _d = tw.interpolate_property(
		child,
		"modulate",
		child.modulate,
		c_1,
		0.125,
		Tween.TRANS_LINEAR
	)
	_d = tw.start()
