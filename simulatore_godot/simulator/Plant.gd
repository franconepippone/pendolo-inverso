extends Node

@export var theta: float = 0
@export var theta_d: float = 0
@export var x: float = 0
@export var x_d: float = 0

var v_prev: float = 0

# constants
@export var g: float = 981
@export var l: float = 10
@export var m: float = .1
@export var M: float = 1

var force: float = 0
var acc: float = 0

var angular_friction = 1
var linear_friction = .01

func sqr(x: float) -> float:
	return x * x

func get_state() -> PendState:
	return PendState.new(theta, theta_d, x, x_d, acc)

func set_state(angle: float, omega: float, pos: float, vel: float):
	theta = angle
	theta_d = omega
	x = pos
	x_d = vel

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func set_force(f: float):
	force = f
	
func set_vel(v_t: float, lerp: float = .1):
	v_prev = x_d
	x_d += (v_t - x_d) * lerp

func apply_input(magnitude: float):
	apply_acc(magnitude)
	set_force(magnitude)

func apply_acc(a: float):
	acc = a

func locked_cart(dt: float):
	#avar acc = (x_d - v_prev) / dt
	#var theta_dd: float = 3/2*1 / l * acc + 3/2*g/l * theta
	var theta_dd: float = 3/2*cos(theta) / l * acc + 3/2*g/l * sin(theta)
	theta_dd -= theta_d * angular_friction
	print(theta_dd)
	# numerical integration
	theta_d += theta_dd * dt 
	
	v_prev = x_d
	x_d += acc * dt;
	if abs(acc) > 0:
		pass
		#acc = 0
	x_d -= x_d * linear_friction * dt
	x += x_d * dt
	theta += theta_d * dt

func free_cart(dt):
	#calculating accelerations
	#https://www.math.uwaterloo.ca/~sacampbe/preprints/fric2.pdf#:~:text=The%20equations%20of%20motion%20of,1
	var theta_dd: float
	var x_dd: float
	
	var J = 4/3 * m * l * l
	var delta = (M + m) * J - pow((m*l*cos(theta)), 2)
	var F = force
	var b = linear_friction * 1000
	var c = angular_friction
	var Ffric = - b * x_d
	
	var numerator = F + Ffric + m*l*sin(theta)*theta_d**2 - (3*m/4)*g*sin(theta)*cos(theta)
	var denominator = M + m - (3*m/4)*cos(theta)**2
	x_dd = numerator / denominator
	
	# Compute theta_dd from eq2
	theta_dd = (3/(4*l))*(g*sin(theta) - cos(theta)*x_dd)
	theta_dd -= theta_d * angular_friction
	
	#x_dd = (m * g * sin(theta) * cos(theta) - m * l * sqr(theta_d) * sin(theta) + force) / (M + m*(1.0 - sqr(cos(theta))))
	#theta_dd = (x_dd * cos(theta) + g * sin(theta)) / l
	
	#theta_dd = (force + m*l*sqr(theta_d)*sin(theta) + g*sin(theta)/cos(theta)) / ((M+m)*(I+m*sqr(l)) / -(m*l*cos(theta)) + m*l*cos(theta))
	#x_dd = (theta_dd * (I + m*l*l) + m*g*l*sin(theta)) / (-m*l*cos(theta))
	
	#theta_dd = (force + M * l * sqr(theta_d) * sin(theta) - m*g*sin(theta)*cos(theta)) / (M*l*cos(theta) + m*l*sin(theta))
	#x_dd = -l*cos(theta)*theta_dd + l*sqr(theta_d)*sin(theta)
		
	# numerical integration
	x_d += x_dd * dt
	theta_d += theta_dd * dt
	###x_d *= linear_damp
	#theta_d *= angular_damp
	
	x += x_d * dt
	theta += theta_d * dt
	
# advances one step in the simulation
func advance(dt):
	free_cart(dt)
