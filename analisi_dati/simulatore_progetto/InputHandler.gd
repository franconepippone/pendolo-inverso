extends Node


@onready var plant = get_parent().get_node("plant")
@onready var controller = get_parent().get_node("controller")

var virtual_target = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("left"):
		virtual_target += -.15
	elif Input.is_action_pressed("right"):
		virtual_target += .15
	
	var viewport_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	var norm_mouse = mouse_pos / viewport_size
	
	var fac = 1920 / viewport_size.x
	virtual_target = (norm_mouse.x - 0.5) * 18 / fac
	
	controller.target_x += (virtual_target - controller.target_x) * .1
	print(plant.x)
