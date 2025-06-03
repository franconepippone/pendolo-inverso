class_name PIDParams
extends RefCounted

var P: float = 0
var I: float = 0
var D: float = 0

func _init(P=0, I=0, D=0) -> void:
	self.P = P
	self.I = I
	self.D = D
	
