extends Area2D

const C = preload("res://Utils/Constants.gd")
const Utils = preload("res://Utils/Utils.gd")
var main: Node2D
var sprite: Sprite
var anim: AnimationPlayer
var value: int
var theta_calc: float
var theta_display: float
var height: float
var target_height: float
var target_theta: float
var min_height: float
var fall_speed: float
var locked: bool = false
var radius: float = 20.0
var tweening: bool = false
var dropping: bool = false
var to_target: bool = false
var to_origin: bool = false
var is_guide: bool = false
var elapsed: float = 0.0

func _ready():
	main = get_parent()
	anim = get_node("AnimationPlayer")
	if not sprite:
		sprite = get_node("Sprite")
	fall_speed = main.fall_speed
	min_height = main.base.radius + radius

func _physics_process(delta):
	# send to target no matter what
	if to_target:
		height = lerp(height, target_height, 0.2)
		if abs(height - target_height) <= 5:
			height = target_height
			to_target = false
		update_pos()

	# send to origin no matter what
	if to_origin:
		theta_calc = lerp(theta_calc, target_theta, 0.2)
		if abs(theta_calc - target_theta) <= 0.05:
			theta_calc = 0
			to_origin = false
		update_pos()

	# do nothing if game over, resetting, or triangle is locked
	if main.game_over or main.resetting or locked:
		return

	# update position if theta_calc is being tweened
	if tweening:
		update_pos()
	
	# move_and_collide if dropping
	if dropping:
		# disable intro lerp if already dropping
		if to_target:
			to_target = false
		# lerp height
		height = lerp(height, min_height, elapsed)
		elapsed += delta * 4
		update_pos()
		if abs(height - min_height) <= 5:
			dropping = false
			lock_self(false)

	# make the triangle fall slowly if not dropping
	else:
		# don't fall if you're the guide and still waiting on the current
		if is_guide and main.curr_triangle.to_target:
			return
		height = max(height - delta * fall_speed, min_height)
		update_pos()
		if height == min_height and not tweening and not is_guide:
			lock_self(false)

func init(curr: bool, val: int, th_c: float, h: float, f_speed: float):
	if curr:
		z_index = 1
		anim.play("idle")
		var size = get_viewport_rect().size
		var h_plus = sqrt(size.x * size.x + size.y * size.y)
		update_pos(th_c, h_plus)
		send_to(h)
		set_value(val)
		fall_speed = f_speed
	else:
		z_index = 2
		scale = Vector2(0.9, 0.9)
		is_guide = true
		update_pos(th_c, h)
		sprite.texture = load("res://Textures/Triangle/triangle.svg")
		sprite.offset = Vector2(0, -50)

func send_to(h: float):
	target_height = h
	to_target = true

func lock_self(error: bool):
	sprite.offset = Vector2.ZERO
	locked = true
	dropping = false
	tweening = false
	main.lock_triangle(error)

func drop():
	# initiate drop
	dropping = true
	elapsed = 0.0

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

func reset(f_speed: float):
	stop_anim()
	fall_speed = f_speed
	to_origin = true
	send_to(C.INITIAL_HEIGHT)
	if theta_calc < 2 * PI - theta_calc:
		target_theta = 0
	else:
		target_theta = 2 * PI

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

func _on_AnimationPlayer_animation_finished(_anim_name):
	if not is_guide:
		anim.play("idle")


func _on_Area2D_area_entered(area):
	if is_guide or locked or area == main.guide_triangle:
		return
	if area == main.base and not tweening:
		return
	lock_self(true)
