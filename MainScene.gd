extends Node2D

var curr_box : KinematicBody2D;
var curr_theta : float = -PI / 2;
var curr_height : float = 200.0;

var base : StaticBody2D;

func _ready():
	# load initial box
	curr_box = load("res://Box.tscn").instance();
	curr_box.position.x = cos(curr_theta) * curr_height;
	curr_box.position.y = sin(curr_theta) * curr_height;
	add_child(curr_box);
	# get base
	base = get_node("Base");

const num_sides : int = 4;
const rot_delta : float = 2 * PI / num_sides;
const rot_speed : float = 8.0;
var rot_left : float = 0;
var rot_dir : int = 0;
var action_list : Array = [];
var next_action : int;

const Action = {
	"WORLD_ROT_LEFT": 0,
	"WORLD_ROT_RIGHT": 1,
	"DROP": 2,
};

const Direction = {
	Action.WORLD_ROT_LEFT: -1,
	Action.WORLD_ROT_RIGHT: 1
}


func _physics_process(delta):
	# on button press, add to list of rotations
	if Input.is_action_just_pressed("world_rot_right"):
		action_list.append(Action.WORLD_ROT_RIGHT);
	elif Input.is_action_just_pressed("world_rot_left"):
		action_list.append(Action.WORLD_ROT_LEFT);
	elif Input.is_action_just_pressed("box_drop"):
		action_list.append(Action.DROP);
	
	# get next action if any are pending
	if action_list.size() > 0 and rot_left == 0:
		next_action = action_list.pop_front();
		if next_action != Action.DROP:
			rot_left = rot_delta;
			rot_dir = Direction[next_action];
		else:
			var dist = curr_box.position.distance_to(base.position);
			var dir = Vector2();
			dir.x = cos(curr_theta) * -dist;
			dir.y = sin(curr_theta) * -dist;
			curr_box.move_and_collide(dir)
		
	# update current box position
	if rot_left > 0:
		var rot_amt = rot_delta * delta * rot_speed;
		# check for over-rotating
		if rot_left - rot_amt < 0:
			rot_amt = rot_left;
		
		# update theta and position
		curr_theta += rot_amt * rot_dir;
		curr_theta = wrapf(curr_theta, -PI, PI);
		curr_box.position.x = cos(curr_theta) * curr_height;
		curr_box.position.y = sin(curr_theta) * curr_height;
		# rotate box so it appear stationary
		curr_box.rotate(rot_dir * rot_amt);
		
		# update rot_left
		rot_left -= rot_amt;
