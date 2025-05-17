extends Control

signal disable_plot 
signal save_data(filename: String)

func _on_show_graphs_toggled(button_pressed):
	if not button_pressed:
		disable_plot.emit()
		$HBoxContainer/VBoxContainer/HBoxContainer/graphs.visible = false
		
	if button_pressed:
		$HBoxContainer/VBoxContainer/HBoxContainer/graphs.visible = true


func _on_button_3_pressed():
	save_data.emit($HBoxContainer/VBoxContainer/option_panel/HBoxContainer/CenterContainer/VBoxContainer/TextEdit.text)
