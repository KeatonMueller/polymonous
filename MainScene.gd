extends Node2D

# possible actions
const Action = {
	"WORLD_ROT_LEFT": 0,
	"WORLD_ROT_RIGHT": 1,
	"DROP": 2,
};

# possible directions
const Direction = {
	Action.WORLD_ROT_LEFT: -1,
	Action.WORLD_ROT_RIGHT: 1
}

const Box = preload("res://Box.tscn");
# current box values
var curr_box : KinematicBody2D;
var curr_theta : float = -PI / 2;
var curr_height : float = 200.0;

# values for base
var base : StaticBody2D;
var rot_delta : float;
var rot_speed : float;

# values for actions
var dist_left : float = 0;
var drop_dir : Vector2 = Vector2();
var drop_speed : float = 4;
var rot_left : float = 0;
var rot_dir : int = 0;
var action_list : Array = [];
var next_action : int;

func _ready():
	# get base
	base = get_node("Base");
	rot_delta = base.rot_delta;
	rot_speed = base.rot_speed;
	add_child(base);
	# load initial box
	curr_box = Box.instance();
	curr_box.position.x = cos(curr_theta) * curr_height;
	curr_box.position.y = sin(curr_theta) * curr_height;
	add_child(curr_box);

func _physics_process(delta):
	# on button press, add to list of actions
	if Input.is_action_just_pressed("world_rot_right"):
		action_list.append(Action.WORLD_ROT_RIGHT);
	elif Input.is_action_just_pressed("world_rot_left"):
		action_list.append(Action.WORLD_ROT_LEFT);
	elif Input.is_action_just_pressed("box_drop"):
		action_list.append(Action.DROP);
	
	# get next action if any are pending
	if action_list.size() > 0 and rot_left == 0 and dist_left == 0:
		next_action = action_list.pop_front();
		if next_action != Action.DROP:
			rot_left = rot_delta;
			rot_dir = Direction[next_action];
		else:
			dist_left = curr_box.position.distance_to(base.position);
			drop_dir.x = cos(curr_theta) * -dist_left * delta * drop_speed;
			drop_dir.y = sin(curr_theta) * -dist_left * delta * drop_speed;
		
	# reposition and rotate box
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
		
	# drop box
	if dist_left > 0:
		var r = curr_box.move_and_collide(drop_dir);
		if r != null and r.collider != null:
			dist_left = 0;
			curr_box.deactivate();
			# initialize a new box
			curr_box = Box.instance();
			curr_box.position.x = cos(curr_theta) * curr_height;
			curr_box.position.y = sin(curr_theta) * curr_height;
			add_child(curr_box);
