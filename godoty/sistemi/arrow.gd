extends Node3D

@export var source: NodePath
@export var var_name: String
@export var color: Color
@export var min_val: float = -INF
@export var max_val: float = INF
@export var lenght_multiplier: float = 1.0


@onready var source_node: Node = get_node(source)
@onready var mesh1: MeshInstance3D = get_node("body")
@onready var mesh2: MeshInstance3D = get_node("body2")

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var mat: StandardMaterial3D = mesh1.mesh.material
	print(mat, mat.albedo_color, color, self)
	mat.albedo_color = color
	# Make it unique if it's shared
	var new_mat: StandardMaterial3D = mat.duplicate()
	new_mat.albedo_color = color
	mesh1.set_surface_override_material(0, new_mat)
	mesh2.set_surface_override_material(0, new_mat)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var val = source_node.get(var_name)
	scale.y = min(max(val, min_val), max_val) * lenght_multiplier
	var shrink = abs(scale.y) / (.05 + abs(scale.y))
	scale.x = shrink
	scale.z = shrink
