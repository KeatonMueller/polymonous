const C = preload("res://Utils/Constants.gd");

# round number to specified number of digits
static func round(num: float, precision=C.PRECISION):
    return stepify(num, pow(10, -precision));