extends Node

var virtual_target = 0
var controller_target_x: float = 0

func get_normalized_mouse_position() -> Vector2:
	var viewport_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	var centered = mouse_pos - viewport_size * 0.5
	return centered / (viewport_size * 0.5)

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
	virtual_target = (norm_mouse.x - 0.5) * 18 / fac * 1.8
	
	controller_target_x += (virtual_target - controller_target_x) * .1
	controller_target_x = virtual_target
