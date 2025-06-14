extends Control

@onready var simulator: PendulumSimulator = get_node("%simulator")
@onready var player3d: PendulumPlayer3D = get_node("%3Dplayer")
@onready var input_handler: Node = get_node("%input_handler")

func _ready() -> void:
	pass

func _on_dplayer_request_new_frame() -> void:
	simulator.set_target_x(input_handler.controller_target_x)
	for i in range(1):
		simulator.step_sim()

func _on_load_sim_toggled(toggled_on: bool) -> void:
	get_node("%sim_list").visible = toggled_on


func _on_p_slider_value_changed(value: float) -> void:
	simulator.get_pid1_params().P = value


func _on_i_slider_value_changed(value: float) -> void:
	simulator.get_pid1_params().I = value


func _on_d_slider_value_changed(value: float) -> void:
	simulator.get_pid1_params().D = value


func _on_new_sim_pressed() -> void:
	var initials = PendState.new(1, -1, 2, 2)
	print(initials.x)
	#PendState.new(-0.04, .15, -4.5, 0)
	var stream: DataStream = simulator.start_sim(PendState.new(0, .2, 0, 0), 0)
	player3d.set_motion_source(stream)
	player3d.set_playing(true)


func _on_save_sim_pressed() -> void:
	DialogManager.show_dialog("save_sim")
	
	#simulator.controller.save_data("C:/Users/ameri/Documents/uni/data.csv")

func _on_save_sim_save(title: String, description: String) -> void:
	var data: DataStream = simulator.get_current_data_stream()
	var runned_sim = RunnedSimulation.new(data, title, description)
	SimManager.add_simulation(runned_sim)
