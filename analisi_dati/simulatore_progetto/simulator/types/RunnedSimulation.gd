class_name RunnedSimulation
extends Resource

var title: String = "default simulation title"
var description: String = ""
var date: Dictionary
var sysdata: DataStream

func _init(sysdata, title = "default simulation title", description = "") -> void:
	self.title = title
	self.description = description
	self.sysdata = sysdata
	self.data = Time.get_datetime_dict_from_system()
