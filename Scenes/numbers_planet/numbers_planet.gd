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
@onready var computer_sound: AudioStreamPlayer3D = $Room/GameComputer/ComputerSound
@onready var message_layer: CanvasLayer = $"IntroLayer"
@onready var message_text: Label = $"IntroLayer/Margin/Box/VBox/IntroText"

const INTRO_LINES: Array[String] = [
	"Matko: Komaj čakam da obiščem svojega prijatelja, ampak najprej moram kupiti vozovnico za ladjo!",
	"Matko: Hmm precej ljudi čaka v vrsti, morda imajo težave... ",
	"Mogoče moram najprej pomagati delavcu, da bo lahko dobim vozovnico.",
	"Za premikanje uporabi tipke W, A, S, D, za interakcijo tipko E. Srečno!",
]

# besedilo po opravljenih vseh postajah
const OUTRO_LINES: Array[String] = [
	"Uspešno si popravil računalnik! Sedaj lahko nadaljuješ svojo avanturo! Pojdi skozi vrata na desni, da zaključiš stopnjo!",
]

var player_near_character: bool = false
var player_near_computer: bool = false
var has_spoken_to_character: bool = false
var arrow_tween: Tween
var opening_game := false

var lines: Array[String] = []
var line_index: int = 0
var message_active: bool = false


func _ready() -> void:
	character_hint_desk.visible = false
	character_hint_computer.visible = false

	gate.visible = NumbersGameProgress.has_played_number_blocks

	character_area.body_entered.connect(_on_character_body_entered)
	character_area.body_exited.connect(_on_character_body_exited)
	computer_area.body_entered.connect(_on_computer_body_entered)
	computer_area.body_exited.connect(_on_computer_body_exited)
	gate_area.body_entered.connect(_on_gate_body_entered)

	start_arrow_bounce()

	if NumbersGameProgress.has_played_number_blocks:
		player.position = Vector3(15.5, 0, 22.5)
		hint_light.position = Vector3(6.8, 2, 25.9)
		hint_arrow.position = Vector3(6.8, 0, 25.9)

	if has_spoken_to_character and not NumbersGameProgress.has_played_number_blocks:
		hint_light.position = Vector3(15.5, 2, 26.5)
		hint_arrow.position = Vector3(15.5, 5, 26.5)

	if not NumbersGameProgress.intro_shown:
		NumbersGameProgress.intro_shown = true
		show_message(INTRO_LINES)
	elif NumbersGameProgress.has_played_number_blocks and not NumbersGameProgress.outro_shown:
		NumbersGameProgress.outro_shown = true
		show_message(OUTRO_LINES)


func show_message(new_lines: Array) -> void:
	lines.assign(new_lines)
	line_index = 0
	message_active = true
	message_text.text = lines[0]
	message_layer.visible = true
	_freeze_player(true)


func advance_message() -> void:
	line_index += 1

	if line_index >= lines.size():
		message_active = false
		message_layer.visible = false
		_freeze_player(false)
	else:
		message_text.text = lines[line_index]


#igralec blizu delavca
func _on_character_body_entered(body: Node3D) -> void:
	if body == player:
		character_hint_desk.visible = true
		player_near_character = true
		has_spoken_to_character = true

	if has_spoken_to_character and not NumbersGameProgress.has_played_number_blocks:
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
	if body == player && NumbersGameProgress.has_played_number_blocks:
		GameState.finish_planet("stevila", 0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if message_active and event.physical_keycode == KEY_SPACE:
			advance_message()
			return

		if event.physical_keycode == KEY_E and player_near_computer and not opening_game:
			opening_game = true

			if computer_sound != null:
				computer_sound.play()
				await computer_sound.finished

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


func _freeze_player(value: bool) -> void:
	if player.has_method("set_frozen"):
		player.set_frozen(value)
	else:
		player.set_physics_process(not value)
