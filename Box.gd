extends KinematicBody2D

onready var color_rect: ColorRect = get_node("ColorRect");
var locked: bool = false;
var radius: float = 20.0; # "radius" ie distance from center to midpoint of side

func deactivate():
	color_rect.color = Color("#158786");
	locked = true;
