extends Node

@export var theta: float = 0
@export var theta_prime: float = 0
@export var x: float = 0
@export var v: float = 0

var v_prev: float = 0

# constants
@export var g: float = 9.81
@export var l: float = 10

var force: float = 0
var acc: float = 0

var angular_damp = .99
var linear_damp = .99

var dt = .1

func sqr(x: float) -> float:
	return x * x

func set_state(angle: float, omega: float, pos: float, vel: float):
	theta = angle
	theta_prime = omega
	x = pos
	v = vel

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func set_force(f: float):
	force = f
	
func set_vel(v_t: float, lerp: float = .1):
	v_prev = v
	v += (v_t - v) * lerp

func apply_acc(a: float):
	acc = a

func locked_cart(dt: float):
	#avar acc = (v - v_prev) / dt
	#var theta_dd: float = 3/2*1 / l * acc + 3/2*g/l * theta
	var theta_dd: float = 3/2*cos(theta) / l * acc + 3/2*g/l * sin(theta)
	
	# numerical integration
	theta_prime += theta_dd * dt 
	theta_prime *= angular_damp
	
	v_prev = v
	v += acc * dt;
	if abs(acc) > 0:
		acc = 0
	v *= linear_damp
	x += v * dt
	theta += theta_prime * dt

func free_cart(dt):
	#calculating accelerations
	var theta_dd: float
	var x_dd: float
	
	#x_dd = (m * g * sin(theta) * cos(theta) - m * l * sqr(theta_prime) * sin(theta) + force) / (M + m*(1.0 - sqr(cos(theta))))
	#theta_dd = (x_dd * cos(theta) + g * sin(theta)) / l
	
	#theta_dd = (force + m*l*sqr(theta_prime)*sin(theta) + g*sin(theta)/cos(theta)) / ((M+m)*(I+m*sqr(l)) / -(m*l*cos(theta)) + m*l*cos(theta))
	#x_dd = (theta_dd * (I + m*l*l) + m*g*l*sin(theta)) / (-m*l*cos(theta))
	
	#theta_dd = (force + M * l * sqr(theta_prime) * sin(theta) - m*g*sin(theta)*cos(theta)) / (M*l*cos(theta) + m*l*sin(theta))
	#x_dd = -l*cos(theta)*theta_dd + l*sqr(theta_prime)*sin(theta)
		
	# numerical integration
	#v += x_dd * dt
	##theta_prime += theta_dd * dt 
	###v *= linear_damp
	#theta_prime *= angular_damp
	
	#x += v * dt
	#theta += theta_prime * dt
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	locked_cart(dt)
