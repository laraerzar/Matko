extends Node3D

@onready var puzzle_layer: CanvasLayer = $PuzzleLayer
@onready var puzzle = $PuzzleLayer/TimePuzzle
@onready var terminal: Area3D = $Terminal
@onready var hint_label: Label3D = $Terminal/Label3D
@onready var player: CharacterBody3D = $Player

var player_near: bool = false
var puzzle_open: bool = false
var solved: bool = false

func _ready() -> void:
	puzzle_layer.visible = false
	terminal.body_entered.connect(_on_body_entered)
	terminal.body_exited.connect(_on_body_exited)
	puzzle.puzzle_completed.connect(_on_puzzle_completed)

func _on_body_entered(body: Node3D) -> void:
	if body == player:
		player_near = true
		hint_label.visible = not solved

func _on_body_exited(body: Node3D) -> void:
	if body == player:
		player_near = false
		hint_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E and player_near and not puzzle_open and not solved:
			open_puzzle()
		elif event.physical_keycode == KEY_ESCAPE and puzzle_open:
			close_puzzle()

func open_puzzle() -> void:
	puzzle_open = true
	hint_label.visible = false
	player.set_frozen(true)
	puzzle_layer.visible = true
	puzzle.start_round()

func close_puzzle() -> void:
	puzzle_open = false
	puzzle_layer.visible = false
	player.set_frozen(false)

func _on_puzzle_completed(mistakes: int) -> void:
	solved = true
	await get_tree().create_timer(1.5).timeout   # let the player read "Odlično!"
	close_puzzle()
	print("Station puzzle solved with ", mistakes, " mistakes")
