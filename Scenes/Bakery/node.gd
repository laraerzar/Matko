extends Node

const INTRO_LINES: Array[String] = [
	"Matko: Ravno pravi čas za svež prigrizek! Ampak v pekarni je kar velika gneča ... Pekarju bom pomagal izpolniti naročila, da lahko čim prej nadaljujem svojo avanturo!",
	"Vsaka stranka želi določen del pice. Razreži pico na prave kose in jih povleci na krožnik.",
	"Za premikanje uporabi tipke W, A, S, D, za interakcijo tipko E. Srečno!",
]

# besedilo po opravljenih vseh naročilih
const OUTRO_LINES: Array[String] = [
	"Odlično! Vsa naročila so izpolnjena in pekar je zelo vesel! Sedaj lahko nadaljuješ svojo avanturo! Pojdi skozi vrata pekarne, da zaključiš stopnjo!",
]

@onready var player = $"../Player"
@onready var message_layer: CanvasLayer = $"../IntroLayer"
@onready var message_text: Label = $"../IntroLayer/Margin/Box/VBox/IntroText"

var lines: Array[String] = []
var line_index: int = 0
var message_active: bool = false


func _ready() -> void:
	message_layer.visible = false
	if not FractionGameProgress.intro_shown:
		FractionGameProgress.intro_shown = true
		show_message(INTRO_LINES)
	elif FractionGameProgress.all_completed() and not FractionGameProgress.outro_shown:
		FractionGameProgress.outro_shown = true
		show_message(OUTRO_LINES)


# pokažem sporočilo in zamrznem igralca, dokler ga ne prebere
func show_message(new_lines: Array) -> void:
	lines.assign(new_lines)
	line_index = 0
	message_active = true
	message_text.text = lines[0]
	message_layer.visible = true
	_freeze_player(true)


# naslednja vrstica ali zaprtje sporočila
func advance_message() -> void:
	line_index += 1

	if line_index >= lines.size():
		message_active = false
		message_layer.visible = false
		_freeze_player(false)
	else:
		message_text.text = lines[line_index]


# presledek pokaže naslednjo vrstico
func _unhandled_input(event: InputEvent) -> void:
	if message_active and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_SPACE:
			advance_message()


func _freeze_player(value: bool) -> void:
	if player.has_method("set_frozen"):
		player.set_frozen(value)
	else:
		player.set_physics_process(not value) # rezerva, če igralec nima set_frozen
