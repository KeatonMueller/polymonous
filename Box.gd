extends KinematicBody2D

onready var color_rect : ColorRect = get_node("ColorRect");

func deactivate():
	color_rect.color = Color("#158786");
