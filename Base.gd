extends StaticBody2D

const num_sides: int = 4;	# number of sides on base
var main: Node2D;
var area: Area2D;
var radius: float = 40.0; # "radius" ie distance from center to midpoint of side
var values: Dictionary = {};
var rects: Array = [];
const Utils = preload("res://Utils.gd");

func _ready():
	main = get_parent();
	area = get_node("Area2D");

func _on_Area2D_body_entered(body):
	# notify main script when a body enter's the Area2D
	main.body_entered(body);

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
		rects[i].color = Utils.COLORS[val];
		print(theta, ', ', val);
