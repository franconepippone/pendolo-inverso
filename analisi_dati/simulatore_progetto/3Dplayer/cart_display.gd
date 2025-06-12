class_name Environment3D
extends Node3D


@onready var pendulum: Node3D = get_node("%arm")
@onready var cart: Node3D = get_node("%cart")
@onready var target_model: Node3D = get_node("%target")


var theta: float = 0
var x: float = 0
var x_dot: float = 0
var u: float = 0
var target: float = 0

const RAD_TO_DEG = 57.2958

func pendvar_set_theta(theta: float):
	self.theta = theta

func pendvar_set_x(x: float):
	self.x = x
	
func pendvar_set_u(u: float):
	self.u = u
	
func pendvar_set_x_dot(x_dot: float):
	self.x_dot = x_dot
	
func pendvar_set_target(target: float):
	self.target = target

func _process(delta: float) -> void:
	cart.position.x = x
	pendulum.rotation.z = -theta
	target_model.position.x = target
	%Camera3D.position.x = lerp(%Camera3D.position.x, x, 0.0)
	
