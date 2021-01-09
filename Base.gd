extends StaticBody2D

onready var cam : Camera2D = get_node("Camera2D")

const num_sides : int = 4;
const rot_delta : float = 2 * PI / num_sides;
const rot_speed : float = 8.0;
var rot_left : float = 0;
var rot_dir : int = 0;
var rot_list : Array = [];

const Direction = {
	"LEFT": 1,
	"RIGHT": -1
};


func _physics_process(delta):
	# on button press, add to list of rotations
	if Input.is_action_just_pressed("move_right"):
		rot_list.append(Direction.RIGHT);
	elif Input.is_action_just_pressed("move_left"):
		rot_list.append(Direction.LEFT);
	
	# set current rotation if any are pending
	if rot_list.size() > 0 and rot_left == 0:
		rot_left = rot_delta;
		rot_dir = rot_list.pop_front();
		
	# update camera rotation
	if rot_left > 0:
		var rot_amt = rot_delta * delta * rot_speed;
		# check for over-rotating
		if rot_left - rot_amt < 0:
			rot_amt = rot_left;
		cam.rotate(rot_dir * rot_amt);
		rot_left -= rot_amt;
