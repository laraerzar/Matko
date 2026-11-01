extends Node

const INTRO_LINES: Array[String] = [
	"Matko: Ravno pravi čas za nakupe! Ampak je kar velika gneča ... Strankam bom pomagal pri tehtanju, da lahko čim prej nadaljujem svojo avanturo!",
	"Za premikanje uporabi tipke W, A, S, D, za interakcijo tipko E, za obračanje kamere pa drži desni gumb miške in jo premikaj. Srečno!",
]

# besedilo po opravljenih vseh postajah
const OUTRO_LINES: Array[String] = [
	"Uspešno opravljeno! Sedaj lahko nadaljuješ svojo avanturo! Pojdi skozi vrata trgovine, da zaključiš stopnjo!",
]

# napis nad vrati, dokler niso opravljene vse postaje
const GATE_TEXT := "Pomagati moraš vsem strankam na vseh postajah, preden lahko nadaljuješ avanturo!"

@onready var player = $"../Player"
@onready var message_layer: CanvasLayer = $"../IntroLayer"
@onready var message_text: Label = $"../IntroLayer/Margin/Box/VBox/IntroText"
@onready var gate_label: Label3D = $"../ExitGate/GateLabel"
@onready var gate_hint_area: Area3D = $"../GateHintArea"

var lines: Array[String] = []
var line_index: int = 0
var message_active: bool = false

func _ready() -> void:
	message_layer.visible = false

	# napis nad vrati je viden samo, dokler niso opravljene vse postaje
	gate_label.text = GATE_TEXT
	gate_label.visible = false
	gate_hint_area.body_entered.connect(_on_gate_area_entered)
	gate_hint_area.body_exited.connect(_on_gate_area_exited)

	if not MarketGameProgress.intro_shown:
		MarketGameProgress.intro_shown = true
		show_message(INTRO_LINES)
	elif MarketGameProgress.all_completed() and not MarketGameProgress.outro_shown:
		MarketGameProgress.outro_shown = true
		show_message(OUTRO_LINES)

# Matko je blizu vrat
func _on_gate_area_entered(body: Node3D) -> void:
	if body == player:
		_update_gate_label(true)

# Matko se je oddaljil od vrat
func _on_gate_area_exited(body: Node3D) -> void:
	if body == player:
		_update_gate_label(false)

# napis je viden samo, če je Matko blizu vrat in niso opravljene vse postaje
func _update_gate_label(player_near: bool) -> void:
	gate_label.visible = player_near and not MarketGameProgress.all_completed()

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

func _freeze_player(value: bool) -> void:
	if player.has_method("set_frozen"):
		player.set_frozen(value)
	else:
		player.set_physics_process(not value) # rezerva, če igralec nima set_frozen

# preslednica ali Enter pomakne besedilo naprej
func _unhandled_input(event: InputEvent) -> void:
	if not message_active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_SPACE or event.physical_keycode == KEY_ENTER:
			advance_message()
			get_viewport().set_input_as_handled()
