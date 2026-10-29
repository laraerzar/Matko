extends Node3D

@onready var character_area: Area3D = $Room/FrontDesk/character/Area3D
@onready var computer_area: Area3D = $Room/GameComputer/Area3D
@onready var character_hint_desk: Label3D = $Room/FrontDesk/character/Label3D
@onready var character_hint_computer: Label3D = $Room/GameComputer/Label3D
@onready var player: CharacterBody3D = $Player
@onready var gate: Node3D = $Room/Gate
@onready var gate_area: Area3D = $Room/Gate/Area3D
@onready var hint_light: OmniLight3D = $Room/OmniLight3D
@onready var hint_arrow: Node3D = $Room/Guide
@onready var arrow: Node3D = $Room/Guide/Arrow


var player_near_character: bool = false
var player_near_computer: bool = false
var has_spoken_to_character: bool = false
var arrow_tween: Tween

func _ready() -> void:
	character_hint_desk.visible = false
	character_hint_computer.visible = false

	gate.visible = GameState.has_played_number_blocks

	character_area.body_entered.connect(_on_character_body_entered)
	character_area.body_exited.connect(_on_character_body_exited)
	computer_area.body_entered.connect(_on_computer_body_entered)
	computer_area.body_exited.connect(_on_computer_body_exited)
	gate_area.body_entered.connect(_on_gate_body_entered)

	start_arrow_bounce()

	if GameState.has_played_number_blocks:
		player.position = Vector3(15.5, 0, 22.5)
		hint_light.position = Vector3(6.8, 2, 25.9)
		hint_arrow.position = Vector3(6.8, 0, 25.9)

	if has_spoken_to_character and not GameState.has_played_number_blocks:
		hint_light.position = Vector3(15.5, 2, 26.5)
		hint_arrow.position = Vector3(15.5, 5, 26.5)

#igralec blizu delavca
func _on_character_body_entered(body: Node3D) -> void:
	if body == player:
		character_hint_desk.visible = true
		player_near_character = true
		has_spoken_to_character = true

	if has_spoken_to_character and not GameState.has_played_number_blocks:
		await get_tree().create_timer(1.0).timeout
		hint_light.position = Vector3(15.5, 2, 26.5)
		hint_arrow.position = Vector3(15.5, 0, 26.5)

#igralec zapusti območje delavca
func _on_character_body_exited(body: Node3D) -> void:
	if body == player:
		character_hint_desk.visible = false
		player_near_character = false

#igralec blizu računalnika
func _on_computer_body_entered(body: Node3D) -> void:
	if body == player:
		character_hint_computer.visible = true
		player_near_computer = true

#igralec zapusti območje računalnika
func _on_computer_body_exited(body: Node3D) -> void:
	if body == player:
		character_hint_computer.visible = false
		player_near_computer = false

#prehod na naslednjo sceno
func _on_gate_body_entered(body: Node3D) -> void:
	if body == player && GameState.has_played_number_blocks:
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/space_station/space_station.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E and player_near_computer:
			open_computer_game()

#mini igra
func open_computer_game() -> void:
	get_tree().change_scene_to_file("res://Scenes/numbers_planet/number_blocks_game.tscn")

#animacija puščice
func start_arrow_bounce() -> void:
	var base_y := arrow.position.y
	arrow_tween = create_tween().set_loops()
	arrow_tween.tween_property(arrow, "position:y", base_y + 0.4, 0.6) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	arrow_tween.tween_property(arrow, "position:y", base_y, 0.6) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
