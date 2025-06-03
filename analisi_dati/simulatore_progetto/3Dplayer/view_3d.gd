class_name PendulumPlayer3D
extends Control

signal request_new_frame

@onready var timebar: HSlider = get_node("%timebar")
@onready var env3d: Environment3D = get_node("%3dEnv")
@onready var time_label: Label = get_node("%time")
@onready var simulated_time: Label = get_node("%maxtime")

@onready var theta_label: Label = get_node("%theta_label")
@onready var theta_dot_label: Label = get_node("%theta_dot_label")
@onready var x_label: Label = get_node("%x_label")
@onready var x_dot_label: Label = get_node("%x_dot_label")

@onready var live_indicator: Panel = get_node("%live_indicator")


var datastream: DataStream = DataStream.new()
var time: float = 0
var playing_source: bool = false

func set_playing(enabled: bool):
	playing_source = enabled

func set_motion_source(stream: DataStream):
	datastream = stream

func _update_timebar():
	timebar.min_value = datastream.get_first_time()
	timebar.max_value = datastream.get_last_time()
	simulated_time.set_text(String.num(datastream.get_last_time(), 2))
	
func _process(delta: float) -> void:
	_update_timebar()
	if playing_source:
		time += delta
		if time > timebar.max_value:
			live_indicator.self_modulate.a = 1.0
			request_new_frame.emit()
		else:
			live_indicator.self_modulate.a = .3
		timebar.value = time	# triggers 3d change as well
	else:
		live_indicator.self_modulate.a = .3

func _show_frame_at(time: float):
	var frame: DataStream.DataFrame = datastream.get_at(time)
	var state: PendState = frame.payload
	
	env3d.pendvar_set_theta(state.theta)
	env3d.pendvar_set_u(state.u)
	env3d.pendvar_set_x(state.x)
	env3d.pendvar_set_x_dot(state.x_dot)
	env3d.pendvar_set_target(state.target)
	
	theta_label.set_text("theta: " + String.num(state.theta, 2))
	theta_dot_label.set_text("theta_dot: " + String.num(state.theta_dot, 2))
	x_label.set_text("x: " + String.num(state.x, 2))
	x_dot_label.set_text("x_dot: " + String.num(state.x_dot, 2))

func _on_timebar_value_changed(value: float) -> void:
	time = value
	_show_frame_at(value)
	time_label.set_text(String.num(time, 2))


func _on_to_start_pressed() -> void:
	timebar.set_value(0)

func _on_to_end_pressed() -> void:
	timebar.set_value(100000)
