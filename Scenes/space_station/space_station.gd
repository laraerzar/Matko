extends Node3D

signal station_completed

@onready var puzzle_layer: CanvasLayer = $PuzzleLayer
@onready var puzzle = $PuzzleLayer/TimePuzzle
@onready var terminal: Area3D = $Terminal
@onready var player: CharacterBody3D = $Player
@onready var hint_label: Label3D = get_node_or_null("Terminal/Label3D")
@onready var guide: Node3D = $Terminal/Guide
@onready var arrow: Node3D = $Terminal/Guide/Arrow
@onready var intro_layer: CanvasLayer = $IntroLayer
@onready var intro_text: Label = $IntroLayer/Margin/Box/VBox/IntroText

var intro_lines: Array[String] = [
	"Matko: Kupi vozovnico za naslednji planet!",
	"Premikaj se s puščicami ali WASD. Pritisni E ob računalniku.",
]
var intro_index: int = 0
var intro_active: bool = false

var player_near: bool = false
var puzzle_open: bool = false
var solved: bool = false
var arrow_tween: Tween

func _ready() -> void:
	puzzle_layer.visible = false
	terminal.body_entered.connect(_on_body_entered)
	terminal.body_exited.connect(_on_body_exited)
	puzzle.puzzle_completed.connect(_on_puzzle_completed)
	start_arrow_bounce()
	show_intro()

# ---------- intro ----------

func show_intro() -> void:
	intro_active = true
	intro_index = 0
	intro_text.text = intro_lines[0]
	intro_layer.visible = true
	player.set_frozen(true)

func advance_intro() -> void:
	intro_index += 1
	if intro_index >= intro_lines.size():
		intro_active = false
		intro_layer.visible = false
		player.set_frozen(false)
	else:
		intro_text.text = intro_lines[intro_index]

# ---------- arrow ----------

func start_arrow_bounce() -> void:
	var base_y := arrow.position.y
	arrow_tween = create_tween().set_loops()
	arrow_tween.tween_property(arrow, "position:y", base_y + 0.4, 0.6) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	arrow_tween.tween_property(arrow, "position:y", base_y, 0.6) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ---------- terminal zone ----------

func set_hint_visible(value: bool) -> void:
	if hint_label != null:
		hint_label.visible = value

func _on_body_entered(body: Node3D) -> void:
	if body == player:
		player_near = true
		set_hint_visible(not solved)

func _on_body_exited(body: Node3D) -> void:
	if body == player:
		player_near = false
		set_hint_visible(false)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if intro_active:
		if event.physical_keycode == KEY_SPACE or event.physical_keycode == KEY_ENTER:
			advance_intro()
		return
	if event.physical_keycode == KEY_E and player_near and not puzzle_open and not solved:
		open_puzzle()
	elif event.physical_keycode == KEY_ESCAPE and puzzle_open:
		close_puzzle()

# ---------- puzzle ----------
func open_puzzle() -> void:
	puzzle_open = true
	set_hint_visible(false)
	player.set_frozen(true)
	puzzle_layer.visible = true
	puzzle.start_round()

func close_puzzle() -> void:
	puzzle_open = false
	puzzle_layer.visible = false
	player.set_frozen(false)

func _on_puzzle_completed(mistakes: int) -> void:
	solved = true
	guide.visible = false
	await get_tree().create_timer(1.5).timeout
	close_puzzle()
	print("Station puzzle solved with ", mistakes, " mistakes")
	station_completed.emit()
