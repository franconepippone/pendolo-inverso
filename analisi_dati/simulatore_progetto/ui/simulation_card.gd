extends Panel


func setup(simulation: RunnedSimulation):
	$%title.text = simulation.title
	$%description.text = simulation.description
