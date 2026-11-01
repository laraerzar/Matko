extends Camera3D

@export var target: Node3D

@export var min_x: float = -10.0
@export var max_x: float = 10.0
@export var min_z: float = -10.0
@export var max_z: float = 10.0

@export var camera_height: float = 8.0
@export var camera_distance: float = 8.0

func _process(_delta: float) -> void:
	if target == null:
		return

	var target_pos = target.global_position

	var cam_x = clampf(target_pos.x, min_x, max_x)
	var cam_z = clampf(target_pos.z + camera_distance, min_z, max_z)

	global_position = Vector3(
		cam_x,
		target_pos.y + camera_height,
		cam_z
	)

	look_at(target_pos, Vector3.UP)