extends Node2D

# possible actions
const Action = {
	"ROT_LEFT": "rot_left",
	"ROT_RIGHT": "rot_right",
	"DROP": "drop",
	"NEW_GAME": "new_game",
};

# directions for a given action
const Direction = {
	Action.ROT_LEFT: -1,
	Action.ROT_RIGHT: 1
}

# reasons the timer might expire
enum TIMER_ACTION {ClearLayer};

# misc constants
const ROT_SPEED: float = 0.2;			# time for rotation (seconds)
const DROP_SPEED: float = 0.125;		# drop duration in seconds (roughly)
const INITIAL_HEIGHT: float = 200.0;	# height boxes start at

# nodes and resources
const Box = preload("res://Box.tscn");
const Utils = preload("res://Utils.gd");
var tw: Tween;
var base: StaticBody2D;
var cam: Camera2D;
var anim: AnimationPlayer;
var timer: Timer;

# current box values
var curr_box: KinematicBody2D;
var theta_calc: float = 0;
var theta_offset: float = -PI / 2;
var theta_display: float = theta_calc + theta_offset;
var curr_height: float = INITIAL_HEIGHT;
var fall_speed: float = 10.0;

# action values
var drop_vector: Vector2 = Vector2();
var dropping: bool = false;
var action_list: Array = [];
var next_action: String;
var tweening: bool = false;
var last_dir: int;
var timer_flag: int;

# angle values
var thetas: Array = [];
var adjacent: Dictionary = {};
var wrap: Dictionary = {};

# game state values
var game_over: bool = false;
var boxes: Dictionary = {};
var box_values: Array;

func _ready():
	tw = get_node("Tween");
	base = get_node("Base");
	cam = base.get_node("Camera2D");
	timer = get_node("Timer");
	calc_thetas(base.num_sides);
	new_game();

func new_game():
	game_over = false;
	# clear out any dropped boxes
	for theta in boxes.keys():
		for child in boxes[theta]:
			remove_child(child);
		boxes.erase(theta);
	# remove curr_box
	if curr_box:
		remove_child(curr_box);
	# empty action_list
	action_list = [];
	# reset transforms
	cam.rotation = 0;
	theta_calc = 0;
	theta_offset = -PI / 2;
	theta_display = theta_calc + theta_offset;
	curr_height = INITIAL_HEIGHT;
	# reset box and base values
	box_values = range(base.num_sides);
	base.set_values(thetas);
	# add new curr_box
	new_box();


func _physics_process(delta):
	if game_over:
		if Input.is_action_just_pressed(Action.NEW_GAME):
			new_game();
		return;
	
	# check for each action
	for action in Action.values():
		if Input.is_action_just_pressed(action):
			action_list.append(action);
			break;

	# perform pending action if idle
	if action_list.size() > 0 and not tweening and not dropping:
		next_action = action_list.pop_front();
		if next_action != Action.DROP:
			rotate(Direction[next_action]);
		else:
			drop();

	# update curr_box position if tweening
	if tweening:
		theta_display = theta_calc + theta_offset;
		curr_box.position.x = cos(theta_display) * curr_height;
		curr_box.position.y = sin(theta_display) * curr_height;

	# update curr_box position if dropping
	if dropping:
		var move_vector = Vector2(drop_vector);
		move_vector.x *= delta / DROP_SPEED;
		move_vector.y *= delta / DROP_SPEED;
		if curr_box.move_and_collide(move_vector) != null:
			dropping = false;
			lock_box();
	# make the box fall slowly if not dropping
	else:
		curr_height -= delta * fall_speed;
		curr_box.position.x = cos(theta_display) * curr_height;
		curr_box.position.y = sin(theta_display) * curr_height;
		
func body_entered(body):
	# detect collision from passive falling
	if not dropping and not tweening and body == curr_box:
		lock_box();

func lock_box():
	var th = Utils.round(theta_calc);
	if base.values[th] != curr_box.value:
		game_over = true;
		curr_box.error();
		return;
	else:
		curr_box.deactivate();
	
	curr_box.position.x = cos(theta_display) * (base.radius + curr_box.radius);
	curr_box.position.y = sin(theta_display) * (base.radius + curr_box.radius);
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
		# erase on a timer
		timer.set_wait_time(0.125);
		timer.start();
		timer_flag = TIMER_ACTION.ClearLayer;
	elif box_values.size() == 0:
		box_values = range(base.num_sides);
	new_box();

func _on_Timer_timeout():
	timer.stop();
	if timer_flag == TIMER_ACTION.ClearLayer:
		for theta in boxes.keys():
			remove_child(boxes[theta].pop_front());
			if boxes[theta].size() == 0:
				boxes.erase(theta);
				
func new_box():
	# instantiate new box
	curr_box = Box.instance();
	anim = curr_box.get_node("AnimationPlayer");
	curr_height = INITIAL_HEIGHT;
	curr_box.position.x = cos(theta_display) * curr_height;
	curr_box.position.y = sin(theta_display) * curr_height;
	curr_box.rotation = theta_calc;
	call_deferred("add_child", curr_box);

	var value = box_values[randi() % box_values.size()];
	box_values.erase(value);
	curr_box.set_value(value);
	
	
func calc_thetas(num_sides: int):
	# calculate possible thetas for given number of sides
	var rot_delta = 2 * PI / num_sides;
	var left_dir = Direction[Action.ROT_LEFT];
	var right_dir = Direction[Action.ROT_RIGHT];
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
	# reset animation if it's running
	if anim.is_playing():
		anim.stop();
		anim.seek(0, true);

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
	tw.interpolate_property(
		curr_box,
		"rotation",
		curr_box.rotation,
		next_box_rot,
		ROT_SPEED,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	);
	# tween theta_calc (which determines curr_box position)
	var th = Utils.round(theta_calc);
	var next_th = adjacent[rot_dir][th];
	tw.interpolate_property(
		self,
		"theta_calc",
		theta_calc,
		next_th,
		ROT_SPEED,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	);
	# tween camera rotation
	var cam_rot = Utils.round(cam.rotation);
	var next_cam_rot = adjacent[rot_dir][cam_rot];
	tw.interpolate_property(
		cam,
		"rotation",
		cam.rotation,
		next_cam_rot,
		ROT_SPEED,
		Tween.TRANS_CUBIC,
		Tween.EASE_OUT
	);
	# start tweening
	tweening = true;
	tw.start();
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
		if last_dir == Direction[Action.ROT_LEFT]:
			anim.play("sway_left");
		elif last_dir == Direction[Action.ROT_RIGHT]:
			anim.play("sway_right");
	elif object == cam and key == ":rotation":
		# wrap rotation if outside of [0, 2PI]
		var rot = Utils.round(cam.rotation);
		if wrap.has(rot):
			cam.rotation = wrap[rot];

func _on_Tween_tween_all_completed():
	# set all tweening to false
	tweening = false;

