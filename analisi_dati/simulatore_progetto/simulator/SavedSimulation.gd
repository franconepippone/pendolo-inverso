class_name SavedSimulation
extends RefCounted

var title: String = "default simulation title"
var date: Dictionary
var sysdata: DataStream

func _init(sysdata, title = "default simulation title") -> void:
	self.title = title
	self.sysdata = sysdata
	self.data = Time.get_datetime_dict_from_system()
