extends KinematicBody2D

const Utils = preload("res://Utils.gd");
onready var color_rect: ColorRect = get_node("ColorRect");
onready var label: Label = get_node("Label");
onready var bar: ColorRect = get_node("Bar");
var locked: bool = false;
var radius: float = 20.0; # "radius" ie distance from center to midpoint of side
var value: int;

func deactivate():
	color_rect.color = Color("#158786");
	locked = true;

func set_value(val: int):
	if not label:
		label = get_node("Label");
	if not bar:
		bar = get_node("Bar");
	label.text = str(val);
	value = val;
	bar.color = Utils.COLORS[val];
