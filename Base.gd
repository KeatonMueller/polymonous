extends StaticBody2D

const num_sides: int = 4;	# number of sides on base
var main: Node2D;
var area: Area2D;
var radius: float = 40.0; # "radius" ie distance from center to midpoint of side

func _ready():
	main = get_parent();
	area = get_node("Area2D");

func _on_Area2D_body_entered(body):
	# notify main script when a body enter's the Area2D
	main.body_entered(body);
