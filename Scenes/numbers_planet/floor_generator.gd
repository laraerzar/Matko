extends Node3D

@export var tile_scene: PackedScene
@export_range(1, 200) var columns: int = 30
@export_range(1, 200) var rows: int = 30
@export var tile_size: float = 1.0

func _ready() -> void:
	if tile_scene == null:
		push_warning("Floor Generator: tile_scene ni nastavljena!")
		return

	for x in range(columns):
		for z in range(rows):
			var tile = tile_scene.instantiate()
			add_child(tile)

			tile.position = Vector3(
				x * tile_size,
				-0.6,
				z * tile_size
			)

	generate_rail()


@export var rail_scene: PackedScene
@export var rail_spacing: float = 4.0
@export var rail_scale: float = 4.0
@export var rail_inset: float = 1.0
@export var rail_offset_x: float = 8.0
@export var rail_offset_z: float = 8.0

func generate_rail() -> void:
	if rail_scene == null:
		return

	var width := columns * tile_size
	var depth := rows * tile_size

	var left := rail_inset
	var right := width - rail_inset
	var front := rail_inset
	var back := depth - rail_inset

	# Sprednja in zadnja stran
	var count_x := int(floor((right - left) / rail_spacing)) + 1

	for i in range(1, count_x - 1):
		var x := left + i * rail_spacing

		place_rail(Vector3(x, 0, front), 0.0)
		place_rail(Vector3(x, 0, back), 0.0)

	# Leva in desna stran
	var count_z := int(floor((back - front) / rail_spacing)) + 1

	for i in range(1, count_z - 1):
		var z := front + i * rail_spacing

		place_rail(Vector3(left, 0, z + rail_offset_z*2), PI / 2.0)
		place_rail(Vector3(right, 0, z + rail_offset_z*2), PI / 2.0)


func place_rail(pos: Vector3, rot_y: float) -> void:
	var rail = rail_scene.instantiate()
	add_child(rail)

	rail.position = Vector3(
		pos.x - rail_offset_x,
		pos.y,
		pos.z - rail_offset_z
	)
	rail.rotation.y = rot_y
	rail.scale = Vector3(rail_scale, rail_scale, rail_scale)
