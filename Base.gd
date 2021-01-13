extends StaticBody2D

const num_sides: int = 4;	# number of sides on base
var main: Node2D;
var radius: float = 40.0; # "radius" ie distance from center to midpoint of side
var values: Dictionary = {};
var rects: Array = [];
const C = preload("res://Constants.gd");

func _ready():
	main = get_parent();

func set_values(thetas: Array):
	if rects.size() == 0:
		for i in range(num_sides):
			rects.append(get_node("ColorRect" + str(i)));
	values = {};
	var pos_vals = range(num_sides);
	for i in range(num_sides):
		var theta = thetas[i + 1];
		var val = pos_vals[randi() % pos_vals.size()];
		pos_vals.erase(val);
		values[theta] = val;
		rects[i].color = C.COLORS[val];
