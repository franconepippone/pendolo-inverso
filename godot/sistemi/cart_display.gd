extends Node3D


@onready var pendulum: Node3D = get_node("arm")
@onready var engine: Node = get_parent().get_node("plant")

var RAD_TO_DEG = 57.2958

# Called when the node enters the scene tree for the first time.
func _ready():
	position.x = -engine.x
	pendulum.rotation.z = engine.theta

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#camera.position.x = cart.position.x
	position.x = engine.x
	pendulum.rotation.z = (engine.theta)
