extends Node2D

# nodes and resources
const Fragment = preload("res://Scenes/Box/Fragment.tscn")
const Utils = preload("res://Utils/Utils.gd")
const C = preload("res://Utils/Constants.gd")
var tw: Tween
var base: StaticBody2D
var cam: Camera2D
var anim: AnimationPlayer
var timer: Timer

# current fragment values
var curr_fragment: KinematicBody2D
var fall_speed: float

# action values
var drop_vector: Vector2 = Vector2()
var action_list: Array
var next_action: String
var last_dir: int
var timer_flag: int

# angle values
var thetas: Array = []
var adjacent: Dictionary = {}
var wrap: Dictionary = {}

# game state values
var game_over: bool = true
var resetting: bool
var tweening: bool
var fragments: Dictionary = {}
var fragment_values: Array
var min_height: float

# trash value to satisfy warnings
var _discard

func _ready():
	randomize()
	tw = get_node("Tween")
	cam = get_node("Camera2D")
	timer = get_node("Timer")
	init_base(4)
	new_game()

func init_base(num_sides: int):
	if base:
		base.queue_free()
	base = load("res://Scenes/Base/Base" + str(num_sides) + ".tscn").instance()
	add_child(base)
	calc_thetas(base.num_sides)

func new_game():
	game_over = false
	tweening = false
	# clear out any dropped fragments
	for theta in fragments.keys():
		for child in fragments[theta]:
			child.queue_free()
		_discard = fragments.erase(theta)
	# remove curr_fragment
	if curr_fragment:
		curr_fragment.deactivate()
		curr_fragment.queue_free()
	# empty action_list
	action_list = []
	# reset fragment and base values
	fragment_values = range(base.num_sides)
	base.set_values(thetas)
	# tween camera back to start (if needed)
	var d1 = abs(cam.rotation)
	var d2 = abs(2 * PI - cam.rotation)
	# pick the shortest distance
	var target = 0.0 if d1 <= d2 else 2 * PI
	if target != cam.rotation:
		_discard = tw.interpolate_property(
			cam,
			"rotation",
			cam.rotation,
			target,
			C.CAM_RESET_SPEED,
			Tween.TRANS_CUBIC,
			Tween.EASE_IN_OUT
		)
		_discard = tw.start()
		resetting = true
	else:
		resetting = false
	# add new curr_fragment
	new_fragment(0)

func _physics_process(delta):
	if game_over:
		if Input.is_action_just_pressed(C.ACTION.NewGame):
			new_game()
		return
	if resetting:
		return

	# check for each action
	for action in C.ACTION.values():
		if Input.is_action_just_pressed(action):
			action_list.append(action)
			break

	# perform pending action if idle
	if action_list.size() > 0 and not tweening and curr_fragment.falling():
		next_action = action_list.pop_front()
		if next_action == C.ACTION.Left or next_action == C.ACTION.Right:
			rotate(C.DIRECTION[next_action])
		elif next_action == C.ACTION.Drop:
			stop_anim()
			curr_fragment.drop()

func lock_collision(body):
	# locked fragment detected a collision with `body`
	if body == curr_fragment:
		lock_fragment()

func lock_fragment(collided=null):
	stop_anim()

	# lose if collided with anything except the base
	if collided != base:
		game_over = true
		return

	# reposition flush with base
	curr_fragment.update_pos(-1, min_height)

	# check if dropped in correct place
	var th = Utils.round(curr_fragment.theta_calc)
	if base.values[th] != curr_fragment.value:
		game_over = true
		return

	# deactivate dropped fragment
	curr_fragment.deactivate()
	# save dropped fragment
	var key = Utils.round(curr_fragment.theta_display)
	if fragments.has(key):
		fragments[key].append(curr_fragment)
	else:
		fragments[key] = [curr_fragment]
	# erase if all are populated
	if fragments.size() == base.num_sides:
		fragment_values = range(base.num_sides)
		base.set_values(thetas)
		fall_speed += 5
		# erase on a timer
		timer.set_wait_time(0.125)
		timer.start()
		timer_flag = C.TIMER_ACTION.ClearLayer
	new_fragment(curr_fragment.theta_calc)

func _on_Timer_timeout():
	timer.stop()
	if timer_flag == C.TIMER_ACTION.ClearLayer:
		for theta in fragments.keys():
			fragments[theta].pop_front().queue_free()
			if fragments[theta].size() == 0:
				_discard = fragments.erase(theta)
				
func new_fragment(theta_calc: float):
	# instantiate new fragment
	curr_fragment = Fragment.instance()
	anim = curr_fragment.get_node("AnimationPlayer")
	curr_fragment.update_pos(theta_calc, C.INITIAL_HEIGHT)
	curr_fragment.rotation = theta_calc
	call_deferred("add_child", curr_fragment)
	# assign value
	var value = fragment_values[randi() % fragment_values.size()]
	fragment_values.erase(value)
	curr_fragment.set_value(value)
	
func calc_thetas(num_sides: int):
	var frag = Fragment.instance()
	min_height = base.radius + frag.radius
	frag.queue_free()
	# calculate possible thetas for given number of sides
	var rot_delta = 2 * PI / num_sides
	var left_dir = C.DIRECTION[C.ACTION.Left]
	var right_dir = C.DIRECTION[C.ACTION.Right]
	adjacent[left_dir] = {}
	adjacent[right_dir] = {}
	var theta = -rot_delta
	# calculate all possible rotation values
	for _i in range(num_sides + 2):
		thetas.append(Utils.round(theta))
		theta += rot_delta
	# record adjacent thetas
	for i in range(num_sides + 1):
		adjacent[right_dir][thetas[i]] = thetas[i + 1]
		adjacent[left_dir][thetas[i + 1]] = thetas[i]
	# wrap values to ensure all thetas stay from [0, 2PI]
	wrap.clear()
	wrap[thetas[0]] = thetas[num_sides]
	wrap[thetas[num_sides + 1]] = thetas[1]

func stop_anim():
	# reset animation if playing
	curr_fragment.stop_anim()
	# stop tweens if active
	if tw.is_active():
		_discard = tw.remove_all()

func rotate(rot_dir):
	"""
	perform a rotation to an adjacent side by tweening:
		- curr_fragment position and rotation
		- camera rotation
	"""
	# tween curr_fragment position and rotation
	curr_fragment.tween_rotation(tw, rot_dir)
	# tween camera rotation
	var cam_rot = Utils.round(cam.rotation)
	var next_cam_rot = adjacent[rot_dir][cam_rot]
	_discard = tw.interpolate_property(
		cam,
		"rotation",
		cam.rotation,
		next_cam_rot,
		C.ROT_SPEED,
		Tween.TRANS_CUBIC,
		Tween.EASE_OUT
	)
	# start tweening
	tweening = true
	_discard = tw.start()
	last_dir = rot_dir

func _on_Tween_tween_completed(object, key):
	if object == curr_fragment and key == ":rotation":
		curr_fragment.wrap_rotation()
	elif object == curr_fragment and key == ":theta_calc":
		curr_fragment.wrap_theta()
		curr_fragment.play_anim(last_dir)
	elif object == cam and key == ":rotation":
		# wrap rotation if outside of [0, 2PI]
		var rot = Utils.round(cam.rotation)
		if wrap.has(rot):
			cam.rotation = wrap[rot]

func _on_Tween_tween_all_completed():
	# set all tweening to false
	curr_fragment.end_tween()
	tweening = false
	resetting = false

