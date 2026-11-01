extends Control

@onready var play_again_button = $Center/VBox/PlayAgainButton

func _ready() -> void:
	play_again_button.pressed.connect(_on_play_again)

func _on_play_again() -> void:
	GameState.start_game()
