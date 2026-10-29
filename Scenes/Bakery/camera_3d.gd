extends Camera3D

@export var smoothing := 6.0

var target: Node3D
var offset := Vector3.ZERO

func _ready() -> void:
	target = get_node("../Player")
	offset = global_position - target.global_position

func _process(delta: float) -> void:
	var wanted := target.global_position + offset
	global_position = global_position.lerp(wanted, clampf(smoothing * delta, 0.0, 1.0))
