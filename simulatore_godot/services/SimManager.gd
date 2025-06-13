extends Node

var simulations: Array[RunnedSimulation] = []

func add_simulation(sim: RunnedSimulation):
	simulations.append(sim)

func get_simulations() -> Array[RunnedSimulation]:
	return simulations.duplicate(false)
