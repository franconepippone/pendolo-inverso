class_name PendulumSimulator
extends Node

@onready var plant = get_node("%plant")
@onready var controller = get_node("%controller")


var SUBSTEPS: int = 10
var TIMESTEP: float = 0.01
var elapsed_time: float = 0.0
var time_limit: float = 100000

var current_data_stream: DataStream = DataStream.new()
var simulating: bool = false

func start_sim(initial_cond: PendState = PendState.new(), time_limit: float = 10000) -> DataStream:
	current_data_stream = DataStream.new()
	simulating = true
	elapsed_time = 0
	self.time_limit = time_limit
	plant.set_state(initial_cond.theta, initial_cond.theta_dot, initial_cond.x, initial_cond.x_dot)
	controller.reset()
	print("simulation started")
	return current_data_stream

func stop_sim():
	simulating = false

func step_sim():
	elapsed_time += TIMESTEP
	controller.control(TIMESTEP)
	for _stp in range(SUBSTEPS):
		plant.advance(TIMESTEP / SUBSTEPS)
	
	# updates datastream
	var current_state: PendState = plant.get_state()
	current_state.u = controller.u
	current_state.target = controller.smooth_target_x
	current_data_stream.put(elapsed_time, current_state)

func get_pid1_params() -> PIDParams:
	return controller.PID1

func get_pid2_params() -> PIDParams:
	return controller.PID2

func set_target_x(target_x: float):
	controller.target_x = target_x

func _process(_delta: float) -> void:
	if simulating:
		if elapsed_time < time_limit:
			step_sim()
