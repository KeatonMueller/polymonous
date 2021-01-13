
const PRECISION: int = 6;

const COLORS: Dictionary = {
    0: Color("ff0000"),
    1: Color("00ff00"),
    2: Color("0000ff"),
    3: Color("ffff00")
}

# round number to PRECISION number of decimals
static func round(num: float, precision=PRECISION):
    return stepify(num, pow(10, -precision));

