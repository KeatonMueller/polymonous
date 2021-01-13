extends Node2D

# nodes and resources
const Box = preload("res://Scenes/Box/Box.tscn");
const Utils = preload("res://Utils/Utils.gd");
const C = preload("res://Utils/Constants.gd");
var tw: Tween;
var base: StaticBody2D;
var cam: Camera2D;
var anim: AnimationPlayer;
var timer: Timer;

# current box values
var curr_box: KinematicBody2D;
var theta_calc: float;
var theta_offset: float;
var theta_display: float;
var curr_height: float;
var fall_speed: float;

# action values
var drop_vector: Vector2 = Vector2();
var action_list: Array;
var next_action: String;
var last_dir: int;
var timer_flag: int;

# angle values
var thetas: Array = [];
var adjacent: Dictionary = {};
var wrap: Dictionary = {};

# game state values
var game_over: bool = true;
var resetting: bool;
var tweening: bool;
var dropping: bool;
var boxes: Dictionary = {};
var box_values: Array;
var min_height: float;

# trash value to satisfy warnings
var _discard;

func _ready():
	randomize();
	tw = get_node("Tween");
	base = get_node("Base4");
	cam = base.get_node("Camera2D");
	timer = get_node("Timer");
	calc_thetas(base.num_sides);
	new_game();

func new_game():
	game_over = false;
	tweening = false;
	dropping = false;
	# clear out any dropped boxes
	for theta in boxes.keys():
		for child in boxes[theta]:
			child.queue_free();
		_discard = boxes.erase(theta);
	# remove curr_box
	if curr_box:
		curr_box.queue_free();
	# empty action_list
	action_list = [];
	# reset transforms
	theta_calc = 0;
	theta_offset = -PI / 2;
	theta_display = theta_calc + theta_offset;
	curr_height = C.INITIAL_HEIGHT;
	fall_speed = C.INITIAL_FALL_SPEED;
	# reset box and base values
	box_values = range(base.num_sides);
	base.set_values(thetas);
	# tween camera back to start (if needed)
	var d1 = abs(cam.rotation);
	var d2 = abs(2 * PI - cam.rotation);
	# pick the shortest distance
	var target = 0.0 if d1 <= d2 else 2 * PI;
	if target != cam.rotation:
		_discard = tw.interpolate_property(
			cam,
			"rotation",
			cam.rotation,
			target,
			C.CAM_RESET_SPEED,
			Tween.TRANS_CUBIC,
			Tween.EASE_IN_OUT
		);
		_discard = tw.start();
		resetting = true;
	else:
		resetting = false;
	# add new curr_box
	new_box();

func _physics_process(delta):
	if game_over:
		if Input.is_action_just_pressed(C.ACTION.NewGame):
			new_game();
		return;
	if resetting:
		return;

	# check for each action
	for action in C.ACTION.values():
		if Input.is_action_just_pressed(action):
			action_list.append(action);
			break;

	# perform pending action if idle
	if action_list.size() > 0 and not tweening and not dropping and curr_height > min_height:
		next_action = action_list.pop_front();
		if next_action == C.ACTION.Left or next_action == C.ACTION.Right:
			rotate(C.DIRECTION[next_action]);
		elif next_action == C.ACTION.Drop:
			drop();
			
	# update curr_box position if tweening
	if tweening:
		theta_display = theta_calc + theta_offset;
		curr_box.position.x = cos(theta_display) * curr_height;
		curr_box.position.y = sin(theta_display) * curr_height;

	# update curr_box position if dropping
	if dropping:
		var move_vector = Vector2(drop_vector);
		move_vector.x *= delta / C.DROP_SPEED;
		move_vector.y *= delta / C.DROP_SPEED;
		if curr_box.move_and_collide(move_vector) != null:
			dropping = false;
			lock_box();
	# make the box fall slowly if not dropping
	else:
		curr_height = max(curr_height - delta * fall_speed, min_height);
		curr_box.position.x = cos(theta_display) * curr_height;
		curr_box.position.y = sin(theta_display) * curr_height;
		if curr_height == min_height and not tweening:
			lock_box();

func lock_collision(body):
	if body == curr_box:
		lock_box();

func lock_box():
	stop_anim();

	# check if dropped in correct place
	var th = Utils.round(theta_calc);
	if not base.values.has(th) or base.values[th] != curr_box.value:
		game_over = true;
		curr_box.error();
		return;

	# deactivate dropped box
	curr_box.deactivate();
	curr_box.position.x = cos(theta_display) * min_height;
	curr_box.position.y = sin(theta_display) * min_height;
	# record dropped box
	var key = Utils.round(theta_display);
	if boxes.has(key):
		boxes[key].append(curr_box);
	else:
		boxes[key] = [curr_box];
	# erase if all are populated
	if boxes.size() == base.num_sides:
		box_values = range(base.num_sides);
		base.set_values(thetas);
		fall_speed += 5;
		# erase on a timer
		timer.set_wait_time(0.125);
		timer.start();
		timer_flag = C.TIMER_ACTION.ClearLayer;
	new_box();

func _on_Timer_timeout():
	timer.stop();
	if timer_flag == C.TIMER_ACTION.ClearLayer:
		for theta in boxes.keys():
			boxes[theta].pop_front().queue_free();
			if boxes[theta].size() == 0:
				_discard = boxes.erase(theta);
				
func new_box():
	# instantiate new box
	curr_box = Box.instance();
	anim = curr_box.get_node("AnimationPlayer");
	curr_height = C.INITIAL_HEIGHT;
	curr_box.position.x = cos(theta_display) * curr_height;
	curr_box.position.y = sin(theta_display) * curr_height;
	curr_box.rotation = theta_calc;
	call_deferred("add_child", curr_box);
	# assign value
	var value = box_values[randi() % box_values.size()];
	box_values.erase(value);
	curr_box.set_value(value);
	
func calc_thetas(num_sides: int):
	var box = Box.instance();
	min_height = base.radius + box.radius;
	box.queue_free();
	# calculate possible thetas for given number of sides
	var rot_delta = 2 * PI / num_sides;
	var left_dir = C.DIRECTION[C.ACTION.Left];
	var right_dir = C.DIRECTION[C.ACTION.Right];
	adjacent[left_dir] = {};
	adjacent[right_dir] = {};
	var theta = -rot_delta;
	# calculate all possible rotation values
	for _i in range(num_sides + 2):
		thetas.append(Utils.round(theta));
		theta += rot_delta;
	# record adjacent thetas
	for i in range(num_sides + 1):
		adjacent[right_dir][thetas[i]] = thetas[i + 1];
		adjacent[left_dir][thetas[i + 1]] = thetas[i];
	# wrap values to ensure all thetas stay from [0, 2PI]
	wrap.clear();
	wrap[thetas[0]] = thetas[num_sides];
	wrap[thetas[num_sides + 1]] = thetas[1];

func drop():
	# initialize drop_vector
	var dist = curr_box.position.distance_to(base.position);
	drop_vector.x = cos(theta_display) * -dist;
	drop_vector.y = sin(theta_display) * -dist;
	dropping = true;
	stop_anim();

func stop_anim():
	# reset animation if playing
	if anim.is_playing():
		anim.stop();
		anim.seek(0, true);
	# stop tweens if active
	if tw.is_active():
		_discard = tw.remove_all()

func rotate(rot_dir):
	"""
	perform a rotation to an adjacent side by tweening:
		- curr_box position
		- curr_box rotation
		- camera rotation
	"""
	# tween curr_box rotation
	var box_rot = Utils.round(curr_box.rotation);
	var next_box_rot = adjacent[rot_dir][box_rot];
	_discard = tw.interpolate_property(
		curr_box,
		"rotation",
		curr_box.rotation,
		next_box_rot,
		C.ROT_SPEED,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	);
	# tween theta_calc (which determines curr_box position)
	var th = Utils.round(theta_calc);
	var next_th = adjacent[rot_dir][th];
	_discard = tw.interpolate_property(
		self,
		"theta_calc",
		theta_calc,
		next_th,
		C.ROT_SPEED,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	);
	# tween camera rotation
	var cam_rot = Utils.round(cam.rotation);
	var next_cam_rot = adjacent[rot_dir][cam_rot];
	_discard = tw.interpolate_property(
		cam,
		"rotation",
		cam.rotation,
		next_cam_rot,
		C.ROT_SPEED,
		Tween.TRANS_CUBIC,
		Tween.EASE_OUT
	);
	# start tweening
	tweening = true;
	_discard = tw.start();
	last_dir = rot_dir;

func _on_Tween_tween_completed(object, key):
	if object == curr_box and key == ":rotation":
		# wrap rotation if outside of [0, 2PI]
		var rot = Utils.round(curr_box.rotation);
		if wrap.has(rot):
			curr_box.rotation = wrap[rot];
	elif object == self and key == ":theta_calc":
		# wrap theta_calc if outside of [0, 2PI]
		var th = Utils.round(theta_calc);
		if wrap.has(th):
			theta_calc = wrap[th];
		theta_display = theta_calc + theta_offset;
		# trigger ending animation
		if last_dir == C.DIRECTION[C.ACTION.Left]:
			anim.play("sway_left");
		elif last_dir == C.DIRECTION[C.ACTION.Right]:
			anim.play("sway_right");
	elif object == cam and key == ":rotation":
		# wrap rotation if outside of [0, 2PI]
		var rot = Utils.round(cam.rotation);
		if wrap.has(rot):
			cam.rotation = wrap[rot];


func _on_Tween_tween_all_completed():
	# set all tweening to false
	tweening = false;
	resetting = false;

