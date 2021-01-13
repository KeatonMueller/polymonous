# possible actions
const ACTION = {
	"Left": "rot_left",
	"Right": "rot_right",
	"Drop": "drop",
	"NewGame": "new_game",
}

# directions for a given action
const DIRECTION = {
	ACTION.Left: -1,
	ACTION.Right: 1
}

const COLORS: Dictionary = {
    0: Color("ff0000"),
    1: Color("00ff00"),
    2: Color("0000ff"),
    3: Color("ffff00"),
    4: Color("00ffff"),
    5: Color("ff00ff"),
}

# reasons the timer might expire
enum TIMER_ACTION {ClearLayer}

# misc constants
const ROT_SPEED: float = 0.2		    # time for rotation (seconds)
const CAM_RESET_SPEED: float = 0.75     # time for camera to reset after each game
const DROP_SPEED: float = 0.125		    # drop duration in seconds (roughly)
const INITIAL_HEIGHT: float = 200.0	    # height boxes start at
const INITIAL_FALL_SPEED: float = 10.0  # initial fall speed of boxes
const PRECISION: int = 6                # default rounding precision