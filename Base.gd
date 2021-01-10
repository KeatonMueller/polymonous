extends StaticBody2D

onready var cam : Camera2D = get_node("Camera2D")

const num_sides : int = 4;	# number of sides on base
const rot_delta : float = 2 * PI / num_sides;	# rotation needed to get to adjacent side
const rot_speed : float = 8.0; # time (1 / rot_speed seconds) needed to do a rotation
var rot_left : float = 0; # degree (theta) left needed in current rotation
var rot_dir : int = 0; # direction (-1 | 1) of rotation
var action_list : Array = []; # list of pending actions

var Action : Dictionary; # possible actions
var Direction : Dictionary; # possible directions

func _ready():
	# load enums from MainScene
	var main_scene = get_node("/root/MainScene");
	Action = main_scene.Action;
	Direction = main_scene.Direction;

func _physics_process(delta):
	# on button press, add to list of actinos
	if Input.is_action_just_pressed("world_rot_right"):
		action_list.append(Action.WORLD_ROT_RIGHT);
	elif Input.is_action_just_pressed("world_rot_left"):
		action_list.append(Action.WORLD_ROT_LEFT);
	
	# set current action if any are pending
	if action_list.size() > 0 and rot_left == 0:
		rot_left = rot_delta;
		rot_dir = Direction[action_list.pop_front()];
		
	# update camera rotation
	if rot_left > 0:
		var rot_amt = rot_delta * delta * rot_speed;
		# check for over-rotating
		if rot_left - rot_amt < 0:
			rot_amt = rot_left;
		cam.rotate(rot_dir * rot_amt);
		rot_left -= rot_amt;
