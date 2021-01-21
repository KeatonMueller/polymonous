extends KinematicBody2D

const C = preload("res://Utils/Constants.gd")
const Utils = preload("res://Utils/Utils.gd")
var main: Node2D
var base: StaticBody2D
var sprite: Sprite
var anim: AnimationPlayer
var value: int
var theta_calc: float
var theta_display: float
var height: float
var target_height: float
var min_height: float
var fall_speed: float
var drop_speed: float = 1000
var locked: bool = false
var radius: float = 20.0
var tweening: bool = false
var dropping: bool = false
var init: bool = false
var offsets: Dictionary = {
	"Color": {
		"x": 0,
		"y": -10
	}
}

func _ready():
	main = get_parent()
	anim = get_node("AnimationPlayer")
	if not sprite:
		sprite = get_node("Sprite")
	fall_speed = main.fall_speed
	min_height = main.base.radius + radius

func _physics_process(delta):
	if init:
		height = max(height - delta * drop_speed, target_height)
		update_pos()
		if height == target_height:
			init = false

	if main.game_over or main.resetting or locked:
		return

	# update position if theta_calc is being tweened
	if tweening:
		update_pos()
	
	# move_and_collide if dropping
	if dropping:
		height = max(height - delta * drop_speed, min_height)
		update_pos()
		if height == min_height:
			sprite.offset.x = offsets.Color.x
			sprite.offset.y = offsets.Color.y
			dropping = false
			lock(main.base)

	# make the triangle fall slowly if not dropping
	else:
		height = max(height - delta * fall_speed, min_height)
		update_pos()
		if height == min_height and not tweening:
			lock(main.base)

func init(val: int, th_c: float, h: float, f_speed: float):
	init = true
	update_pos(th_c, h + 200)
	target_height = h
	set_value(val)
	fall_speed = f_speed

func deactivate():
	sprite.offset.x = offsets.Color.x
	sprite.offset.y = offsets.Color.y
	locked = true

func lock(col=null):
	locked = true
	dropping = false
	tweening = false
	main.lock_triangle(col)

func drop():
	# initiate drop
	# anim.play("drop")
	dropping = true

func update_pos(th_c: float=-1, h: float=-1):
	# reposition triangle based on theta and height
	if th_c != -1:
		theta_calc = th_c
	if h != -1:
		height = h

	theta_display = theta_calc + C.THETA_OFFSET
	position.x = cos(theta_display) * height
	position.y = sin(theta_display) * height
	rotation = theta_calc

func tween_rotation(tw: Tween, rot_dir: int):
	# NOTE: caller must trigger tw.start()
	tweening = true
	var th = Utils.round(theta_calc)
	var next_th = main.adjacent[rot_dir][th]
	main._discard = tw.interpolate_property(
		self,
		"theta_calc",
		theta_calc,
		next_th,
		C.ROT_SPEED,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)

func end_tween(dir: int):
	tweening = false
	# wrap theta to keep it in [0, 2PI]
	var th = Utils.round(theta_calc)
	if main.wrap.has(th):
		theta_calc = main.wrap[th]
		rotation = main.wrap[th]

	# trigger ending animation
	if dir == C.DIRECTION[C.ACTION.Left]:
		anim.play("sway_left")
	elif dir == C.DIRECTION[C.ACTION.Right]:
		anim.play("sway_right")

func set_height(h: float):
	height = h

func falling():
	return not tweening and not dropping and height > min_height

func stop_anim():
	if anim and anim.is_playing():
		anim.stop()
		anim.seek(0, true)

func set_value(val: int):
	if not sprite:
		sprite = get_node("Sprite")
	sprite.texture = load("res://Textures/Triangle/triangle_" + str(val) + ".svg")
	value = val

func _on_Area2D_body_entered(body):
	if locked:
		main.lock_collision(body)
	else:
		# TODO: decide how to handle non-dropping collisions
		pass


func _on_AnimationPlayer_animation_finished(anim_name):
	# if anim_name == "drop":
	anim.play("idle")
