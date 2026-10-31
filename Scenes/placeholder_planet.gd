extends Control

@onready var title_label: Label = $Center/VBox/Title
@onready var finish_button: Button = $Center/VBox/FinishButton

func _ready() -> void:
	var id := GameState.current_planet
	if id == "":
		title_label.text = "Konec igre! Matko je pri prijatelju."
		finish_button.text = "Igraj znova"
	else:
		title_label.text = GameState.planet_name(id) + " (začasna scena)"
		finish_button.text = "Končaj planet"
	finish_button.pressed.connect(_on_finish)

func _on_finish() -> void:
	if GameState.current_planet == "":
		GameState.start_game()
	else:
		GameState.finish_planet(GameState.current_planet, 0)
