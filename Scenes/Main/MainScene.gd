extends Node2D

# nodes and resources
const Triangle = preload("res://Scenes/Triangle/Triangle.tscn")
const Utils = preload("res://Utils/Utils.gd")
const C = preload("res://Utils/Constants.gd")
var tw: Tween
var base: StaticBody2D
var cam: Camera2D
var anim: AnimationPlayer
var timer: Timer
var score_label: RichTextLabel

# current triangle values
var curr_triangle: KinematicBody2D
var fall_speed: float

# action values
var drop_vector: Vector2 = Vector2()
var action_list: Array
var next_action: String
var last_dir: int
var timer_flag: int

# angle values
var thetas: Array
var adjacent: Dictionary
var wrap: Dictionary

# game state values
var game_over: bool = true
var resetting: bool
var tweening: bool
var triangles: Dictionary = {}
var triangle_values: Array
var min_height: float
var base_sizes: Array = [4, 5, 6]
var base_idx: int
var score: int

# trash value to satisfy warnings
var _discard

func _ready():
	randomize()
	tw = get_node("Tween")
	cam = get_node("Camera2D")
	timer = get_node("Timer")
	score_label = get_node("Camera2D/ScoreLabel")
	new_game()

func init_base():
	var num_sides = base_sizes[base_idx % 3]
	base_idx += 1
	if base:
		base.queue_free()
	base = load("res://Scenes/Base/Base" + str(num_sides) + ".tscn").instance()
	add_child(base)
	calc_thetas(base.num_sides)

func new_game():
	base_idx = 0
	init_base()
	game_over = false
	tweening = false
	fall_speed = C.INITIAL_FALL_SPEED
	timer_flag = C.TIMER_ACTION.None
	score = 0
	score_label.set_score(score)
	# clear out any dropped triangles
	for theta in triangles.keys():
		for child in triangles[theta]:
			child.queue_free()
		_discard = triangles.erase(theta)
	# remove curr_triangle
	if curr_triangle:
		curr_triangle.queue_free()
	# empty action_list
	action_list = []
	# reset triangle and base values
	triangle_values = range(base.num_sides)
	base.set_values(thetas)
	# tween camera back to start (if needed)
	cam_to_start()
	# add new curr_triangle
	new_triangle(0)

func cam_to_start():
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

func _physics_process(_delta):
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
	if action_list.size() > 0 and not tweening and curr_triangle.falling():
		next_action = action_list.pop_front()
		if next_action == C.ACTION.Left or next_action == C.ACTION.Right:
			rotate(C.DIRECTION[next_action])
		elif next_action == C.ACTION.Drop:
			stop_anim()
			curr_triangle.drop()

func lock_collision(body):
	# locked triangle detected a collision with `body`
	if body == curr_triangle:
		lock_triangle()

func lock_triangle(collided=null):
	stop_anim()

	# lose if collided with anything except the base
	if collided != base:
		game_over = true
		return

	# reposition flush with base
	curr_triangle.update_pos(-1, min_height)

	# check if dropped in correct place
	var th = Utils.round(curr_triangle.theta_calc)
	if base.values[th] != curr_triangle.value:
		base.lock_triangle(th, curr_triangle.value)
		game_over = true
		return

	base.lock_triangle(th, curr_triangle.value)

	# deactivate dropped triangle
	curr_triangle.deactivate()
	# save dropped triangle
	var key = Utils.round(curr_triangle.theta_display)
	if triangles.has(key):
		triangles[key].append(curr_triangle)
	else:
		triangles[key] = [curr_triangle]
	# erase if all are populated
	if triangles.size() == base.num_sides:
		score += int(fall_speed)
		score_label.set_score(score)
		fall_speed += 5
		# erase on a timer
		timer.set_wait_time(0.25)
		timer.start()
		timer_flag = C.TIMER_ACTION.ClearLayer
	else:
		new_triangle(curr_triangle.theta_calc)

func _on_Timer_timeout():
	timer.stop()
	if timer_flag == C.TIMER_ACTION.ClearLayer:
		for theta in triangles.keys():
			triangles[theta].pop_front().queue_free()
			if triangles[theta].size() == 0:
				_discard = triangles.erase(theta)
		init_base()
		triangle_values = range(base.num_sides)
		base.set_values(thetas)
		action_list.clear()
		cam_to_start()
		new_triangle(0)
				
func new_triangle(theta_calc: float):
	# instantiate new triangle
	curr_triangle = Triangle.instance()
	anim = curr_triangle.get_node("AnimationPlayer")
	var value = triangle_values[randi() % triangle_values.size()]
	triangle_values.erase(value)
	curr_triangle.init(value, theta_calc, C.INITIAL_HEIGHT, fall_speed)

	add_child(curr_triangle)
	
func calc_thetas(num_sides: int):
	thetas = []
	adjacent = {}
	wrap = {}
	var frag = Triangle.instance()
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
	wrap[thetas[0]] = thetas[num_sides]
	wrap[thetas[num_sides + 1]] = thetas[1]

func stop_anim():
	# reset animation if playing
	curr_triangle.stop_anim()
	# stop tweens if active
	if tw.is_active():
		_discard = tw.remove_all()

func rotate(rot_dir):
	"""
	perform a rotation to an adjacent side by tweening:
		- curr_triangle position and rotation
		- camera rotation
	"""
	# tween curr_triangle position and rotation
	curr_triangle.tween_rotation(tw, rot_dir)
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
	if object == curr_triangle and key == ":theta_calc":
		curr_triangle.end_tween(last_dir)
	elif object == cam and key == ":rotation":
		# wrap rotation if outside of [0, 2PI]
		var rot = Utils.round(cam.rotation)
		if wrap.has(rot):
			cam.rotation = wrap[rot]

func _on_Tween_tween_all_completed():
	# set all tweening to false
	tweening = false
	resetting = false
