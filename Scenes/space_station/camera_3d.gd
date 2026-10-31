extends Camera3D

@export var target: Node3D

# Limits are wide open for now. Tighten them later once it works.
@export var min_x: float = -40.0
@export var max_x: float = 40.0
@export var min_z: float = -40.0
@export var max_z: float = 40.0

@export var camera_height: float = 12.0
@export var camera_distance: float = 12.0
@export var aim_height: float = 3.0
@export_range(-90.0, 90.0) var yaw_degrees: float = 0.0

func _ready() -> void:
	print("Camera script running. Target = ", target)

func _process(_delta: float) -> void:
	if target == null:
		return

	var target_pos := target.global_position

	var offset := Vector3(0.0, camera_height, camera_distance)
	offset = offset.rotated(Vector3.UP, deg_to_rad(yaw_degrees))

	var cam_pos := target_pos + offset
	cam_pos.x = clampf(cam_pos.x, min_x, max_x)
	cam_pos.z = clampf(cam_pos.z, min_z, max_z)

	global_position = cam_pos
	look_at(target_pos + Vector3(0.0, aim_height, 0.0), Vector3.UP)
