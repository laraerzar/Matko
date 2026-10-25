extends Control

const BLOCK_SIZE := 44.0
const GRID_STEP := 62.0
const MAX_BLOCKS := 9

@export_range(1, 999) var target_number: int = 243
@export var questions_to_win: int = 5
var question_number := 0

@onready var board: Panel = $CenterContainer/VBoxContainer/Board
@onready var prompt_label: Label = $CenterContainer/VBoxContainer/PromptLabel
@onready var target_label: Label = $CenterContainer/VBoxContainer/TargetLabel
@onready var count_label: Label = $CenterContainer/VBoxContainer/CountLabel
@onready var feedback_label: Label = $CenterContainer/VBoxContainer/FeedbackLabel
@onready var progress_label: Label = $CenterContainer/VBoxContainer/ProgressLabel

@onready var ones_button: Button = $CenterContainer/VBoxContainer/ItemBar/OnesButton
@onready var tens_button: Button = $CenterContainer/VBoxContainer/ItemBar/TensButton
@onready var hundreds_button: Button = $CenterContainer/VBoxContainer/ItemBar/HundredsButton

@onready var check_button: Button = $CenterContainer/VBoxContainer/CheckAnswerButton

var counts := {1: 0, 10: 0, 100: 0}
var used_cells: Dictionary = {}
var blocks: Array[Control] = []

var dragging := false
var dragging_value := 0
var dragging_color := Color.WHITE
var preview: Control

var dragged_block: Control
var dragged_from_cell := Vector2i(-1, -1)

var correct_count := 0
var mistakes := 0
var locked := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := $CenterContainer
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vbox := $CenterContainer/VBoxContainer
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	randomize()

	prompt_label.text = "Predstavi število z enotskimi kockami"

	progress_label.text = "Napredek: %d / 5" % [correct_count]
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	ones_button.text = "ENICE"
	tens_button.text = "DESETICE"
	hundreds_button.text = "STOTICE"

	ones_button.gui_input.connect(
		_on_source_gui_input.bind(1, Color(0.25, 0.65, 1.0))
	)
	tens_button.gui_input.connect(
		_on_source_gui_input.bind(10, Color(0.3, 0.85, 0.45))
	)
	hundreds_button.gui_input.connect(
		_on_source_gui_input.bind(100, Color(1.0, 0.65, 0.2))
	)

	check_button.text = "Preveri odgovor"
	check_button.pressed.connect(check_answer)

	board.clip_contents = true

	apply_colors()

	new_question()


func new_question() -> void:
	clear_blocks()

	locked = false
	check_button.disabled = false

	question_number += 1

	match question_number:
		1:
			target_number = randi_range(1, 99)
		2,3:
			target_number = randi_range(100, 499)
		4,5:
			target_number = randi_range(100, 999)

	target_label.text = "Sestavi število: %d" % target_number
	feedback_label.text = "Povleci kocke v okvir."

	progress_label.text = "Pravilni odgovori: %d / %d" % [
		correct_count, questions_to_win
	]

	update_count()



func clear_blocks() -> void:
	for block in blocks:
		if is_instance_valid(block):
			block.queue_free()

	blocks.clear()
	used_cells.clear()

	counts = {1: 0, 10: 0, 100: 0}


func _on_source_gui_input(
	event: InputEvent,
	value: int,
	color: Color
) -> void:
	if locked or dragging:
		return

	if not event is InputEventMouseButton:
		return

	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	if counts[value] >= MAX_BLOCKS:
		feedback_label.text = "Te vrste lahko uporabiš največ 9."
		return

	dragging = true
	dragging_value = value
	dragging_color = color

	preview = make_block_visual(value, color)
	add_child(preview)
	preview.z_index = 100
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	move_preview()



func make_block_visual(value: int, color: Color) -> Control:
	var visual := Control.new()

	var unit_size := 5.0
	var gap := 1.0

	# Enica: 1 kocka; desetica: 10 v črti;
	# stotica: 10 vrstic po 10 kock.
	if value == 1:
		visual.custom_minimum_size = Vector2(24, 24)
		visual.size = Vector2(24, 24)

		var unit := ColorRect.new()
		unit.position = Vector2.ZERO
		unit.size = Vector2(24, 24)
		unit.color = color
		unit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.add_child(unit)

	elif value == 10:
		visual.custom_minimum_size = Vector2(10 * unit_size + 9 * gap, unit_size)
		visual.size = visual.custom_minimum_size

		for i in range(10):
			var unit := ColorRect.new()
			unit.position = Vector2(i * (unit_size + gap), 0)
			unit.size = Vector2(unit_size, unit_size)
			unit.color = color
			unit.mouse_filter = Control.MOUSE_FILTER_IGNORE
			visual.add_child(unit)

	elif value == 100:
		visual.custom_minimum_size = Vector2(
			10 * unit_size + 9 * gap,
			10 * unit_size + 9 * gap
		)
		visual.size = visual.custom_minimum_size

		for y in range(10):
			for x in range(10):
				var unit := ColorRect.new()
				unit.position = Vector2(
					x * (unit_size + gap),
					y * (unit_size + gap)
				)
				unit.size = Vector2(unit_size, unit_size)
				unit.color = color
				unit.mouse_filter = Control.MOUSE_FILTER_IGNORE
				visual.add_child(unit)

	return visual



func _input(event: InputEvent) -> void:
	if not dragging:
		return

	if event is InputEventMouseMotion:
		move_preview()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			drop_block()


func move_preview() -> void:
	if not is_instance_valid(preview):
		return

	var local_mouse := (
		get_global_transform_with_canvas().affine_inverse()
		* get_global_mouse_position()
	)

	preview.position = local_mouse - preview.size / 2.0



func drop_block() -> void:
	var mouse := get_global_mouse_position()
	var placed := false

	if board.get_global_rect().has_point(mouse):
		var local_mouse := (
			board.get_global_transform_with_canvas().affine_inverse()
			* mouse
		)

		var cols := floori(board.size.x / GRID_STEP)
		var rows := floori(board.size.y / GRID_STEP)

		if cols > 0 and rows > 0:
			var target_cell := Vector2i(
				clampi(floori(local_mouse.x / GRID_STEP), 0, cols - 1),
				clampi(floori(local_mouse.y / GRID_STEP), 0, rows - 1)
			)

			var free_cell := find_free_cell(target_cell, cols, rows)

			if free_cell.x >= 0:
				if is_instance_valid(dragged_block):
					finish_dragged_block(free_cell)
					placed = true
				else:
					create_block(free_cell, dragging_value, dragging_color)
					counts[dragging_value] += 1
					placed = true

	if is_instance_valid(preview):
		preview.queue_free()

	preview = null

	if is_instance_valid(dragged_block):
		if not placed:
			remove_dragged_block()

		dragged_block = null

	dragging = false
	dragging_value = 0

	update_count()



func find_free_cell(
	target: Vector2i,
	cols: int,
	rows: int
) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := 2147483647

	for y in range(rows):
		for x in range(cols):
			var cell := Vector2i(x, y)

			if used_cells.has(cell):
				continue

			var distance := absi(x - target.x) + absi(y - target.y)

			if distance < best_distance:
				best_distance = distance
				best = cell

	return best


func create_block(
	cell: Vector2i,
	value: int,
	color: Color
) -> void:
	var block := make_block_visual(value, color)

	block.position = Vector2(
		cell.x * GRID_STEP + 4,
		cell.y * GRID_STEP + 4
	)

	block.mouse_filter = Control.MOUSE_FILTER_STOP
	block.set_meta("value", value)
	block.set_meta("cell", cell)
	block.set_meta("block_color", color)

	block.gui_input.connect(_on_block_gui_input.bind(block))

	board.add_child(block)
	blocks.append(block)
	used_cells[cell] = block


func _on_block_gui_input(
	event: InputEvent,
	block: Control
) -> void:
	if locked or dragging:
		return

	if not event is InputEventMouseButton:
		return

	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	dragging = true
	dragged_block = block

	var value: int = block.get_meta("value")
	dragging_value = value
	dragging_color = block.get_meta("block_color")
	dragged_from_cell = block.get_meta("cell")

	used_cells.erase(dragged_from_cell)
	blocks.erase(block)
	counts[value] -= 1

	# Med premikanjem ustvarimo vizualni predogled.
	preview = make_block_visual(value, dragging_color)
	add_child(preview)
	preview.z_index = 100
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	block.visible = false
	move_preview()
	update_count()


func finish_dragged_block(cell: Vector2i) -> void:
	if not is_instance_valid(dragged_block):
		return

	dragged_block.position = Vector2(
		cell.x * GRID_STEP + 4,
		cell.y * GRID_STEP + 4
	)

	dragged_block.set_meta("cell", cell)
	dragged_block.visible = true

	used_cells[cell] = dragged_block
	blocks.append(dragged_block)

	counts[dragging_value] += 1


func remove_dragged_block() -> void:
	if is_instance_valid(dragged_block):
		dragged_block.queue_free()

	dragged_block = null


func check_answer() -> void:
	if locked:
		return

	var total: int = (
		counts[100] * 100
		+ counts[10] * 10
		+ counts[1]
	)

	if total == target_number:
		locked = true
		correct_count += 1
		check_button.disabled = true

		progress_label.text = "Pravilni odgovori: %d / %d" % [
			correct_count, questions_to_win
		]

		if correct_count >= questions_to_win:
			feedback_label.text = "Odlično! Računalnik je popravljen!"
		else:
			await get_tree().create_timer(1.0).timeout
			new_question()
	else:
		mistakes += 1
		feedback_label.text = (
			"Poskusi znova. Sestavil si %d, cilj pa je %d."
			% [total, target_number]
		)


func update_count() -> void:
	count_label.text = (
		"Stotice: %d | Desetice: %d | Enice: %d"
		% [counts[100], counts[10], counts[1]]
	)


func apply_colors() -> void:
	# Ozadje celotne igre
	RenderingServer.set_default_clear_color(
		Color("#E8F5FF")
	)

	# Plošča za sestavljanje števil
	var board_style := StyleBoxFlat.new()
	board_style.bg_color = Color("#FFFFFF")
	board_style.border_color = Color("#8ED8FF")
	board_style.set_border_width_all(3)
	board_style.set_corner_radius_all(18)
	board.add_theme_stylebox_override(
		"panel", board_style
	)

	# Besedila
	prompt_label.add_theme_color_override(
		"font_color", Color("#35618D")
	)
	target_label.add_theme_color_override(
		"font_color", Color("#7B61C9")
	)
	progress_label.add_theme_color_override(
	"font_color", Color("#E58B25")
	)
	count_label.add_theme_color_override(
		"font_color", Color("#35618D")
	)
	feedback_label.add_theme_color_override(
		"font_color", Color("#269B69")
	)


	style_button(ones_button, "#42A5F5")
	style_button(tens_button, "#66D17A")
	style_button(hundreds_button, "#FFB547")
	style_button(check_button, "#9B83F5")

func style_button(button: Button, color_hex: String) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(color_hex)
	normal.set_corner_radius_all(14)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(color_hex).lightened(0.12)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(color_hex).darkened(0.12)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("#FFFFFF"))
	button.add_theme_font_size_override("font_size", 16)
