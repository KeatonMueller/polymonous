extends KinematicBody2D

const C = preload("res://Constants.gd");
var color_rect: ColorRect;
var label: Label;
var bar: ColorRect;
var locked: bool = false;
var radius: float = 20.0; # "radius" ie distance from center to midpoint of side
var value: int;
var main: Node2D;

func _ready():
	main = get_parent();
	color_rect = get_node("ColorRect");
	if not label:
		label = get_node("Label");
	if not bar:
		bar = get_node("Bar");

func deactivate():
	color_rect.color = Color("158786");
	locked = true;

func error():
	color_rect.color = Color("ff0000")

func set_value(val: int):
	if not label:
		label = get_node("Label");
	if not bar:
		bar = get_node("Bar");
	label.text = str(val);
	value = val;
	bar.color = C.COLORS[val];


func _on_Area2D_body_entered(body):
	if locked:
		main.lock_collision(body);
