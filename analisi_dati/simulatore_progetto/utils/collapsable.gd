extends VBoxContainer


@export var text: String = "collapse"

@onready var child_node = self.get_children()[1]

# Called when the node enters the scene tree for the first time.
func _ready():
	$Panel/HBoxContainer/Label.text = text


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_check_box_toggled(button_pressed):
	if button_pressed:
		child_node.visible = true
	else:
		child_node.visible = false
