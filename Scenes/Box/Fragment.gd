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
var min_height: float
var fall_speed: float = C.INITIAL_FALL_SPEED
var locked: bool = false
var radius: float = 14.0
var tweening: bool = false
var dropping: bool = false
var drop_vector: Vector2 = Vector2()

func _ready():
	main = get_parent()
	anim = get_node("AnimationPlayer")
	if not sprite:
		sprite = get_node("Sprite")

	min_height = main.base.radius + radius

func _physics_process(delta):
	if main.game_over or main.resetting or locked:
		return

	# update position if theta_calc is being tweened
	if tweening:
		update_pos()
	
	# move_and_collide if dropping
	if dropping:
		var move_vector = Vector2(drop_vector)
		move_vector.x *= delta / C.DROP_SPEED
		move_vector.y *= delta / C.DROP_SPEED
		var collision = move_and_collide(move_vector)
		if collision != null:
			dropping = false
			main.lock_fragment(collision.collider)
	# make the fragment fall slowly if not dropping
	else:
		height = max(height - delta * fall_speed, min_height)
		update_pos()
		if height == min_height and not tweening:
			main.lock_fragment(main.base)

func drop():
	# initiate drop
	var dist = position.distance_to(main.base.position)
	drop_vector.x = cos(theta_display) * -dist
	drop_vector.y = sin(theta_display) * -dist
	dropping = true

func update_pos(th_c: float=-1, h: float=-1):
	# reposition fragment based on theta and height
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
	var frag_rot = Utils.round(rotation)
	var next_frag_rot = main.adjacent[rot_dir][frag_rot]
	main._discard = tw.interpolate_property(
		self,
		"rotation",
		rotation,
		next_frag_rot,
		C.ROT_SPEED,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)
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

func end_tween():
	tweening = false

func wrap_theta():
	var th = Utils.round(theta_calc)
	if main.wrap.has(th):
		theta_calc = main.wrap[th]
	
func wrap_rotation():
	var rot = Utils.round(rotation)
	if main.wrap.has(rot):
		rotation = main.wrap[rot]

func play_anim(dir: int):
	# trigger ending animation
	if dir == C.DIRECTION[C.ACTION.Left]:
		anim.play("sway_left")
	elif dir == C.DIRECTION[C.ACTION.Right]:
		anim.play("sway_right")

func set_height(h: float):
	height = h

func falling():
	return not tweening and not dropping and height > min_height

func deactivate():
	locked = true

func stop_anim():
	if anim and anim.is_playing():
		anim.stop()
		anim.seek(0, true)

func set_value(val: int):
	if not sprite:
		sprite = get_node("Sprite")
	sprite.texture = load("res://Textures/Fragment/sprite_" + str(val) + ".png")
	value = val

func _on_Area2D_body_entered(body):
	if locked:
		main.lock_collision(body)
	else:
		# TODO: decide how to handle non-dropping collisions
		pass
