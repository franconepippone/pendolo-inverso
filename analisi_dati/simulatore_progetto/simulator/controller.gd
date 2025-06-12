class_name Controller
extends Node

@export_node_path("Node") var _model
@onready var model = get_node(_model)

enum ControllerType {
	PID,
	SF,
	NONE
}

var mode: ControllerType = ControllerType.PID

@onready var rng = RandomNumberGenerator.new()

var target_x: float = 0
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


#var K = [111.6441, 104.132, -2.544443, -6.731056]
var K = [9917.5735, 853.96744, -75.147199, -41.810653]

func _ready() -> void:
	rng.randomize()
	#Utils.write_csv_file("readings/ciccio.csv", ["input", "theta", "theta_dot", "pos", "vel"])
	#PID1 = PIDParams.new(-10000, 0, -300)
	#PID2 = PIDParams.new(-50, 0, -30)
	
# pid
#PIDParams.new(-100, -5, -30)
var PID1: PIDParams = PIDParams.new(100000, 0,0)
var err_last = 0
var err_int = 0

var PID2: PIDParams = PIDParams.new(-0, 0, -0)
var err_last2 = 0
var err_int2 = 0

var target_theta: float = 0.0

func dot(arr1: Array, arr2: Array) -> float:
	var sm = 0
	for i in range(len(arr1)):
		sm += arr1[i] * arr2[i]
	return sm

var smooth_model_x: float = 0
var smooth_target_x: float = 0
var last_u: float = 0

func PID(dt):
	
	# sistema interno

	#pid
	#var err = (target_x - model.x)
	#var err_der = (err-err_last)/model.dt
	#err_last = err
	#err_int += err * model.dt
	#var r = err * p + err_der * d + err_int * i
	
	smooth_model_x += (model.x - smooth_model_x) * .1
	var err2 = (smooth_target_x - smooth_model_x)
	var err_der2 = (err2-err_last2)/dt
	err_last2 = err2
	err_int2 += err2 * dt
	var w = err2 * PID2.P + err_der2 * PID2.D + err_int2 * PID2.I
	
	
	var err = (model.theta)
	var err_der = (err-err_last)/dt
	err_last = err
	err_int += err * dt
	var r = err * PID1.P + err_der * PID1.D + err_int * PID1.I
	
	#var acc = (K1 * (model.theta + .1) + K2 * model.theta_prime)
	u = r + w
	u = clamp(u, -10000, 10000)
	const p =1
	var pack_arrived: bool = randf() < p
	if pack_arrived:
		model.apply_input(u)
		last_u = u
	else:
		model.apply_input(last_u)
		last_u *= .9
	
func SF():
	u = -dot(K, [model.theta, model.theta_prime, model.x - smooth_target_x, model.v])
	
	u = clamp(u, -40000, 40000)
	
	model.apply_input(u)
	print(u)
	
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
	smooth_model_x = 0
	last_u = 0

func control(dt):
	
	smooth_target_x += (target_x - smooth_target_x) * .1
	match mode:
		ControllerType.SF: SF()
		ControllerType.PID: PID(dt)
		_: return

	
	var new_line = [u, 
		model.theta + rng.randfn(0, 0.00),
		model.theta_d + rng.randfn(0, 0.00),
		model.x + rng.randfn(0, 0.00),
		model.x_d + rng.randfn(0, 0.00)
	]
	readings.append(new_line)
