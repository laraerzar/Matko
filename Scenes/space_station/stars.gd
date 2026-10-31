extends Node3D

@export var count: int = 400
@export var radius: float = 90.0

func _ready() -> void:
	var star := SphereMesh.new()
	star.radius = 0.2
	star.height = 0.4
	star.radial_segments = 6
	star.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.WHITE
	star.material = mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = star
	mm.instance_count = count
	for i in count:
		var dir := Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		if dir.length() < 0.1:
			dir = Vector3.UP
		var s := randf_range(0.5, 1.6)
		var basis := Basis.IDENTITY.scaled(Vector3.ONE * s)
		mm.set_instance_transform(i, Transform3D(basis, dir.normalized() * radius))

	var instance := MultiMeshInstance3D.new()
	instance.multimesh = mm
	add_child(instance)
