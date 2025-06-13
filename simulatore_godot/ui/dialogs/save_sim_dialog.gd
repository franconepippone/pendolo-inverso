extends Window

signal save(title: String, description: String)
signal export_csv


func _on_save_pressed() -> void:
	save.emit($%titleedit.text, $%descriptionedit.text)

func _on_exp_csv_pressed() -> void:
	pass # Replace with function body.


func _on_cancel_pressed() -> void:
	hide()
