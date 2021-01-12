extends Node2D

# possible actions
const Action = {
	"ROT_LEFT": "rot_left",
	"ROT_RIGHT": "rot_right",
	"DROP": "drop",
};

# directions for a given action
const Direction = {
	Action.ROT_LEFT: -1,
	Action.ROT_RIGHT: 1
}

const ROT_SPEED: float = 0.2;
const PRECISION: int = 6;
const INITIAL_HEIGHT: float = 200.0;

const Box = preload("res://Box.tscn");
onready var tw: Tween = get_node("Tween");
var base: StaticBody2D;
var cam: Camera2D;
var anim: AnimationPlayer;

# current box values
var curr_box: KinematicBody2D;
var theta_calc: float = 0;
var theta_offset: float = -PI / 2;
var theta_display: float = theta_calc + theta_offset;
var curr_height: float = 200.0;

var drop_vector: Vector2 = Vector2();
var drop_speed: float = 5.0;
var dropping: bool = false;
var action_list: Array = [];
var next_action: String;
var tweening: bool = false;
var Adjacent: Dictionary = {};
var Wrap: Dictionary = {};
var boxes: Dictionary = {};
var last_dir: int;

func _ready():
	tw = get_node("Tween");
	base = get_node("Base");
	cam = base.get_node("Camera2D");
	calc_thetas(base.num_sides);
	# load initial box
	new_box();

func _physics_process(delta):
	for action in Action.values():
		if Input.is_action_just_pressed(action):
			action_list.append(action);
			break;
	
	if action_list.size() > 0 and not tweening and not dropping:
		next_action = action_list.pop_front();
		if next_action != Action.DROP:
			rotate(Direction[next_action]);
		else:
			drop();

	if tweening:
		theta_display = theta_calc + theta_offset;
		curr_box.position.x = cos(theta_display) * curr_height;
		curr_box.position.y = sin(theta_display) * curr_height;

	if dropping:
		var move_vector = Vector2(drop_vector);
		move_vector.x *= delta * drop_speed;
		move_vector.y *= delta * drop_speed;
		if curr_box.move_and_collide(move_vector) != null:
			dropping = false;
			lock_box();
			new_box();

func lock_box():
	var key = approx(theta_display, PRECISION);
	if boxes.has(key):
		boxes[key].append(curr_box);
	else:
		boxes[key] = [curr_box];

	if boxes.size() == base.num_sides:
		for theta in boxes.keys():
			remove_child(boxes[theta].pop_front());
			if boxes[theta].size() == 0:
				boxes.erase(theta);

func new_box():
	curr_box = Box.instance();
	anim = curr_box.get_node("AnimationPlayer");
	curr_height = INITIAL_HEIGHT;
	var new_pos = Vector2();
	new_pos.x = cos(theta_display) * curr_height;
	new_pos.y = sin(theta_display) * curr_height;
	curr_box.position = new_pos;
	curr_box.rotation = theta_calc;
	add_child(curr_box);
	
func calc_thetas(num_sides):
	var rot_delta = 2 * PI / num_sides;
	var left_dir = Direction[Action.ROT_LEFT];
	var right_dir = Direction[Action.ROT_RIGHT];
	var rotations: Array = [];
	Adjacent[left_dir] = {};
	Adjacent[right_dir] = {};
	var theta = -rot_delta;
	for _i in range(num_sides + 2):
		rotations.append(approx(theta, PRECISION));
		theta += rot_delta;
	for i in range(num_sides + 1):
		Adjacent[right_dir][rotations[i]] = rotations[i + 1];
		Adjacent[left_dir][rotations[i + 1]] = rotations[i];
	Wrap.clear();
	Wrap[rotations[0]] = rotations[num_sides];
	Wrap[rotations[num_sides + 1]] = rotations[1];

func drop():
	var dist = curr_box.position.distance_to(base.position);
	drop_vector.x = cos(theta_display) * -dist;
	drop_vector.y = sin(theta_display) * -dist;
	dropping = true;

func rotate(rot_dir):
	var box_rot = approx(curr_box.rotation, PRECISION);
	var next_box_rot = Adjacent[rot_dir][box_rot];
	tw.interpolate_property(
		curr_box,
		"rotation",
		curr_box.rotation,
		next_box_rot,
		ROT_SPEED,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	);

	var th = approx(theta_calc, PRECISION);
	var next_th = Adjacent[rot_dir][th];
	tw.interpolate_property(
		self,
		"theta_calc",
		theta_calc,
		next_th,
		ROT_SPEED,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	);

	var cam_rot = approx(cam.rotation, PRECISION);
	var next_cam_rot = Adjacent[rot_dir][cam_rot];
	tw.interpolate_property(
		cam,
		"rotation",
		cam.rotation,
		next_cam_rot,
		ROT_SPEED,
		Tween.TRANS_CUBIC,
		Tween.EASE_OUT
	);

	tweening = true;
	tw.start();
	last_dir = rot_dir;

func _on_Tween_tween_completed(object, key):
	if object == curr_box and key == ":rotation":
		var rot = approx(curr_box.rotation, PRECISION);
		if Wrap.has(rot):
			curr_box.rotation = Wrap[rot];
	elif object == self and key == ":theta_calc":
		var th = approx(theta_calc, PRECISION);
		if Wrap.has(th):
			theta_calc = Wrap[th];
		theta_display = theta_calc + theta_offset;
		if last_dir == Direction[Action.ROT_LEFT]:
			anim.play("sway_left");
		elif last_dir == Direction[Action.ROT_RIGHT]:
			anim.play("sway_right");
	elif object == cam and key == ":rotation":
		var rot = approx(cam.rotation, PRECISION);
		if Wrap.has(rot):
			cam.rotation = Wrap[rot];

func _on_Tween_tween_all_completed():
	tweening = false;

func approx(num, precision):
	return stepify(num, pow(10, -precision));

