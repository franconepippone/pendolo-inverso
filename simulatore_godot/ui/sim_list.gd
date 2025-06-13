extends Control

var simulation_card := preload("res://ui/simulation_card.tscn")

@onready var sim_container: VBoxContainer = get_node("%sim_container")

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		if sim_container != null:
			for child in sim_container.get_children():
				child.queue_free()
		return
		
	# when is visible
	for sim in SimManager.get_simulations():
		var card = simulation_card.instantiate()
		card.setup(sim)
		sim_container.add_child(card)
	
