extends KinematicBody2D

var sprite: Sprite
var locked: bool = false
var radius: float = 14.0
var value: int
var main: Node2D

func _ready():
	main = get_parent()
	if not sprite:
		sprite = get_node("Sprite")

func deactivate():
	locked = true

func error():
	pass

func set_value(val: int):
	if not sprite:
		sprite = get_node("Sprite")
	sprite.texture = load("res://Textures/Fragment/sprite_" + str(val) + ".png")
	value = val

func _on_Area2D_body_entered(body):
	if locked:
		main.lock_collision(body)
