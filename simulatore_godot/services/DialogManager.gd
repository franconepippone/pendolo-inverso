extends Node


func show_dialog(name: String):
	var dialog: Window = get_tree().current_scene.get_node("%dialogs_container").get_node(name)
	if dialog == null:
		push_warning("dialog: %s not found" % name)
		return
	
	dialog.popup()
