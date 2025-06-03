class_name PendState
extends RefCounted

var theta: float = 0
var theta_dot: float = 0
var x: float = 0
var x_dot: float = 0
var u: float = 0
var target: float = 0

func _init(theta = 0, theta_dot = 0, x = 0, x_dot = 0, u = 0, target = 0) -> void:
	self.theta = theta
	self.theta_dot = theta_dot
	self.x = x
	self.x_dot = x_dot
	self.u = u
	self.target = target
	
