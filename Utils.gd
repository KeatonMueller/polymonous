const C = preload("res://Constants.gd");

# round number to PRECISION number of decimals
static func round(num: float, precision=C.PRECISION):
    return stepify(num, pow(10, -precision));

