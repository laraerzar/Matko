extends Node3D

@onready var character_area: Area3D = $Room/FrontDesk/character/Area3D
@onready var computer_area: Area3D = $Room/GameComputer/Area3D
@onready var character_hint_desk: Label3D = $Room/FrontDesk/character/Label3D
@onready var character_hint_computer: Label3D = $Room/GameComputer/Label3D
@onready var player: CharacterBody3D = $Player


var player_near_character: bool = false
var player_near_computer: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	character_hint_desk.visible = false
	character_hint_computer.visible = false
	character_area.body_entered.connect(_on_character_body_entered)
	character_area.body_exited.connect(_on_character_body_exited)
	computer_area.body_entered.connect(_on_computer_body_entered)
	computer_area.body_exited.connect(_on_computer_body_exited)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_character_body_entered(body: Node3D) -> void:
	if body == player:
		character_hint_desk.visible = true
		player_near_character = true


func _on_character_body_exited(body: Node3D) -> void:
	if body == player:
		character_hint_desk.visible = false
		player_near_character = false

func _on_computer_body_entered(body: Node3D) -> void:
	if body == player:
		character_hint_computer.visible = true
		player_near_computer = true

func _on_computer_body_exited(body: Node3D) -> void:
	if body == player:
		character_hint_computer.visible = false
		player_near_computer = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E and player_near_computer:
			open_computer_game()

func open_computer_game() -> void:
	get_tree().change_scene_to_file("res://Scenes/numbers_planet/number_blocks_game.tscn")