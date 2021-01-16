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
    0: Color("65ebff"),
    1: Color("ff6482"),
    2: Color("53ff33"),
    3: Color("e88bdf"),
    4: Color("ba9aff"),
    5: Color("ff00ff"),
}

# reasons the timer might expire
enum TIMER_ACTION {ClearLayer}

# misc constants
const ROT_SPEED: float = 0.2		    # time for rotation (seconds)
const CAM_RESET_SPEED: float = 0.75     # time for camera to reset after each game
const DROP_SPEED: float = 0.125		    # drop duration in seconds (roughly)
const INITIAL_HEIGHT: float = 200.0	    # height fragments start at
const INITIAL_FALL_SPEED: float = 10.0  # initial fall speed of fragments
const PRECISION: int = 6                # default rounding precision
const THETA_OFFSET: float = -PI / 2     # display offset from theta used in calculations