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

# modulation values for each sprite's glow
const MODULATIONS: Dictionary = {
    0: { "r": 2, "g": 2, "b": 2 },
    1: { "r": 2, "g": 2, "b": 2 },
    2: { "r": 2, "g": 2, "b": 2 },
    3: { "r": 3, "g": 1.1, "b": 0 },
    4: { "r": 2, "g": 2, "b": 2 },
    5: { "r": 1, "g": 3, "b": 3 },
}

# reasons the timer might expire
enum TIMER_ACTION {None, ClearLayer}

# misc constants
const ROT_SPEED: float = 0.2		    # time for rotation (seconds)
const CAM_RESET_SPEED: float = 0.75     # time for camera to reset after each game
const DROP_SPEED: float = 0.125		    # drop duration in seconds (roughly)
const INITIAL_HEIGHT: float = 200.0	    # height triangles start at
const INITIAL_FALL_SPEED: float = 10.0  # initial fall speed of triangles
const MAX_FALL_SPEED: float = 100.0     # maximum fall speed of triangles
const PRECISION: int = 6                # default rounding precision
const THETA_OFFSET: float = -PI / 2     # display offset from theta used in calculations