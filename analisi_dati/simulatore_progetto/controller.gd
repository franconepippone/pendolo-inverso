class_name Controller
extends Node

@export_node_path("Node") var _model
@onready var model = get_node(_model)

var is_active: bool = true


var mode: int = 0 

@onready var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	print(model)
	rng.randomize() 

var target_x: float = 2
var u: float = 0

var readings: Array = []

 #var K = [83.470704862029692,  76.229220066719364,  -0.770480746240340, -3.559327810019547]

# FROM LINEARIZED SYSTEM DATA00
#var K = [123.897065279827, 113.149838583851, -2.36605691095563, -6.91320916425096]

# FROM NON LINEARIZED SYSTEM DATA
#var K = [40.4920778247494, 30.171670274331, 0.528144460816729, -0.388709798980321]
#var K = [62.1080606864852, 56.7156159924045, -0.839131789982944, -2.71177390882563]

# FROM NON LINEARIZED + NOISE
#var K = [-0.177961293195180, -0.0625818786606077, 0.919469249134928, 1.49973245346416]

# Stima fatta su:
# dataset: noisy2.csv
# ident opts: state-space-model, +disturbance component, PEM technique 
#var K = [62.673889842818, 57.023871752961, -0.841972268486185, -2.72560264392413]

# stima fatta su noisy_normal
#var K = [6.3563479402859, 2.5075415869239, -0.630460255739673, 0.596306350969665] # NON VA


var K = [111.6441, 104.132, -2.544443, -6.731056]

func _enter_tree():
	Utils.write_csv_file("readings/ciccio.csv", ["input", "theta", "theta_dot", "pos", "vel"])
	pass
# pid
var p = -100
var i = -5
var d = -30
var err_last = 0
var err_int = 0

var p2 = -1
var i2 = 0
var d2 = -2.2
var err_last2 = 0
var err_int2 = 0

var target_theta: float = 0.0

func dot(arr1: Array, arr2: Array) -> float:
	var sm = 0
	for i in range(len(arr1)):
		sm += arr1[i] * arr2[i]
	return sm

func PID():
	
	# sistema interno

	#pid
	#var err = (target_x - model.x)
	#var err_der = (err-err_last)/model.dt
	#err_last = err
	#err_int += err * model.dt
	#var r = err * p + err_der * d + err_int * i
	var err2 = (target_x - model.x)
	var err_der2 = (err2-err_last2)/model.dt
	err_last2 = err2
	err_int2 += err2 * model.dt
	var w = err2 * p2 + err_der2 * d2 + err_int2 * i2
	
	
	var err = (model.theta)
	var err_der = (err-err_last)/model.dt
	err_last = err
	err_int += err * model.dt
	var r = err * p + err_der * d + err_int * i
	
	#var acc = (K1 * (model.theta + .1) + K2 * model.theta_prime)
	u = r + w
	
	u = clamp(u, -10, 10)
	model.apply_acc(u)

func SF():
	u = -dot(K, [model.theta, model.theta_prime, model.x - target_x, model.v])
	
	u = clamp(u, -40, 40)
	
	model.apply_acc(u)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not is_active:
		return
	
	if mode == 0:
		SF()
	elif mode == 1:
		PID()

	
	var new_line = [u, 
		model.theta + rng.randfn(0, 0.01),
		model.theta_prime + rng.randfn(0, 0.01),
		model.x + rng.randfn(0, 0.05),
		model.v + rng.randfn(0, 0.05)
	]
	readings.append(new_line)

func set_mode(new_mode: int):
	err_int = 0
	mode = new_mode

func save_data(filename: String):
	readings.insert(0, ["input", "theta", "theta_dot", "pos", "vel"])
	Utils.write_csv_file(filename, readings)
	readings = []

func reset():
	readings.clear()
	err_last = 0
	err_int = 0
	err_last2 = 0
	err_int2 = 0
