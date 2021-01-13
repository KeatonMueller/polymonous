
# round number to specified number of digits
static func approx(num: float, precision: int):
    return stepify(num, pow(10, -precision));