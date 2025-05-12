extends Node2D


@export_node_path("Node2D") var _cart

@onready var cart = get_node(_cart)
@onready var pendulum = cart.get_node("arm")
@onready var engine = get_node("physics engine")
@onready var controller = get_node("controller")

@onready var camera = get_node("Camera2D")
@onready var target_line = get_node("target")

var RAD_TO_DEG = 57.2958

func _ready():
	# set initial conditions
	cart.position.x = engine.x
	pendulum.rotation_degrees = engine.theta * RAD_TO_DEG

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#camera.position.x = cart.position.x
	cart.position.x = engine.x * 1000*0 + 300 
	target_line.position.x = controller.target_x * 1000 
	pendulum.rotation_degrees = -(engine.theta) * RAD_TO_DEG
	
	controller.target_x = get_global_mouse_position().x / 1000
	
	if Input.is_action_just_pressed("spacebar"):
		controller.is_active = not controller.is_active
