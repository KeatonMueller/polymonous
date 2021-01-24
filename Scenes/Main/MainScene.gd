extends Node2D

# nodes and resources
const Triangle = preload("res://Scenes/Triangle/Triangle.tscn")
const Utils = preload("res://Utils/Utils.gd")
const C = preload("res://Utils/Constants.gd")
var tw: Tween
var base: Area2D
var cam: Camera2D
var anim: AnimationPlayer
var timer: Timer
var score_label: RichTextLabel

# triangle values
var curr_triangle: Area2D
var guide_triangle: Area2D
var fall_speed: float
var min_height: float
var triangles: Array = []
var triangle_values: Array

# action values
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
var base_sizes: Array = [4, 5, 6]
var base_idx: int

# trash value to satisfy warnings
var _discard

func _ready():
	"grab references to different nodes and start the game"
	randomize()
	tw = get_node("Tween")
	cam = get_node("Camera2D")
	timer = get_node("Timer")
	score_label = get_node("Camera2D/ScoreLabel")
	new_game()

func init_base():
	"initialize a new base"
	var num_sides = base_sizes[base_idx]
	base_idx = base_idx + 1 if base_idx < base_sizes.size() - 1 else 0
	if base:
		base.queue_free()
	base = load("res://Scenes/Base/Base" + str(num_sides) + ".tscn").instance()
	add_child(base)
	calc_thetas(base.num_sides)

func new_game():
	"start up a new game"
	base_idx = 0
	init_base()
	game_over = false
	tweening = false
	fall_speed = C.INITIAL_FALL_SPEED
	timer_flag = C.TIMER_ACTION.None
	score_label.reset_score()
	# clear out any dropped triangles
	for tri in triangles:
		tri.queue_free()
	triangles.clear()
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
	# set up guide_triangle
	new_guide_triangle()

func cam_to_start():
	"tween camera rotation to 0 degrees"
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
	"""
	process physics
	this is actually mostly just input handling, as most of the
	physics is handled in the Triangle class
	"""
	# only listen for new game actions if game over
	if game_over:
		if Input.is_action_just_pressed(C.ACTION.NewGame):
			new_game()
		return

	# check for each action
	for action in C.ACTION.values():
		if Input.is_action_just_pressed(action):
			action_list.append(action)
			break
	
	# don't perform any new actions if resetting
	if resetting:
		return

	# perform pending action if idle
	if action_list.size() > 0 and not tweening and curr_triangle.falling():
		next_action = action_list.pop_front()
		if next_action == C.ACTION.Left or next_action == C.ACTION.Right:
			rotate(C.DIRECTION[next_action])
		elif next_action == C.ACTION.Drop:
			stop_anim()
			curr_triangle.drop()
			$SFX.play("drop0")

func lock_triangle(valid: bool, drop_distance: float):
	"lock triangle position after it collided with something"
	stop_anim()

	# check if the collision wasn't valid
	if not valid:
		game_over = true

		# check to see if double placed
		var th = Utils.round(curr_triangle.theta_calc)
		if base.values.has(th):
			# display at offset to triangle already placed
			curr_triangle.update_pos(-1, min_height + 10)
		return

	# reposition flush with base
	curr_triangle.update_pos(-1, min_height)

	# check if dropped in correct place
	var th = Utils.round(curr_triangle.theta_calc)
	if base.values[th] != curr_triangle.value:
		game_over = true
		return

	# save dropped triangle
	triangles.append(curr_triangle)

	# add score for correct placement
	score_label.inc_score(50)

	# add drop bonus
	if drop_distance > 0:
		score_label.inc_score(drop_distance)

	# erase if all are populated
	if triangles.size() == base.num_sides:
		next_base()
	else:
		new_triangle(curr_triangle.theta_calc)
		guide_triangle.send_to(C.INITIAL_HEIGHT)

func next_base():
	"set up the next base"
	resetting = true
	# add score for clearing a layer
	score_label.inc_score(int(fall_speed) * 100)
	# increase fall speed by 20%
	fall_speed = min(fall_speed * 1.2, C.MAX_FALL_SPEED)
	guide_triangle.anim.play("idle")
	# erase after a delay
	timer.set_wait_time(0.5)
	timer.start()
	timer_flag = C.TIMER_ACTION.ClearLayer
	action_list.clear()

func _on_Timer_timeout():
	"finish setting up the next base once timer finishes"
	timer.stop()
	if timer_flag == C.TIMER_ACTION.ClearLayer:
		resetting = false
		# clear old triangles
		for tri in triangles:
			tri.queue_free()
		triangles.clear()
		# init new base
		init_base()
		triangle_values = range(base.num_sides)
		base.set_values(thetas)
		# reset camera and guide, and spawn new triangle
		cam_to_start()
		new_triangle(0)
		guide_triangle.reset(fall_speed)

func new_guide_triangle():
	"initialize the guide_triangle"
	# reset if already present
	if guide_triangle:
		guide_triangle.reset(fall_speed)
		return
	# otherwise init
	guide_triangle = Triangle.instance()
	add_child(guide_triangle)
	guide_triangle.init(false, -1, 0, C.INITIAL_HEIGHT, fall_speed)

func new_triangle(theta_calc: float):
	"initialize a new curr_triangle"
	curr_triangle = Triangle.instance()
	add_child(curr_triangle)
	anim = curr_triangle.get_node("AnimationPlayer")
	var value = triangle_values[randi() % triangle_values.size()]
	triangle_values.erase(value)
	curr_triangle.init(true, value, theta_calc, C.INITIAL_HEIGHT, fall_speed)
	
func calc_thetas(num_sides: int):
	"""
	calculate theta values for current base size
	store adjacent thetas and wrap-around values
	"""
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
	"stop all animations"
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
	$SFX.play("rotate" + str(randi() % 5))
	# tween curr_triangle position and rotation
	curr_triangle.tween_rotation(tw, rot_dir)
	guide_triangle.tween_rotation(tw, rot_dir)
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
	"handle tween completions"
	if object == curr_triangle and key == ":theta_calc":
		curr_triangle.end_tween(last_dir)
	elif object == guide_triangle and key == ":theta_calc":
		guide_triangle.end_tween(last_dir)
	elif object == cam and key == ":rotation":
		# wrap rotation if outside of [0, 2PI]
		var rot = Utils.round(cam.rotation)
		if wrap.has(rot):
			cam.rotation = wrap[rot]

func _on_Tween_tween_all_completed():
	"set all tweening to false"
	tweening = false
	resetting = false
