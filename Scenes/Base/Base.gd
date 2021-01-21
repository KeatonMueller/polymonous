extends Area2D

const C = preload("res://Utils/Constants.gd")
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
		bases[i].texture = load("res://Textures/Space/space_" + str(val) + ".svg")
		bases[i].modulate.r = C.MODULATIONS[val].r
		bases[i].modulate.g = C.MODULATIONS[val].g
		bases[i].modulate.b = C.MODULATIONS[val].b
