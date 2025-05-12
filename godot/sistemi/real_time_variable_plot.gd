extends Control

@export var source: NodePath
@export var var_name: String
@export var time_window: float = 10

@onready var graph = $graph
@onready var source_node = get_node(source)
var plot_item: PlotItem

var elapsed_time: float = 0.0

var _enabled: bool = false



# Called when the node enters the scene tree for the first time.
func _ready():
	plot_item = graph.add_plot_item("", Color.WHITE)
	graph.x_min = 0
	graph.x_max = time_window
	source_node = get_node(source)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not _enabled:
		return
	
	elapsed_time += 0.01
	var val = source_node.get(var_name)
	if not val:
		val = 0.0
	plot_item.add_point(Vector2(elapsed_time, val))
	if visible:
		if elapsed_time > time_window:
			graph.x_min = elapsed_time - time_window
			graph.x_max = elapsed_time

func disable():
	print("DISABLED")
	hide()
	_enabled = false
	print(_enabled)
	elapsed_time = 0
	plot_item.remove_all()
	graph.x_min = 0
	graph.x_max = time_window
	
func _on_visibility_changed():
	if not _enabled:
		_enabled = true
