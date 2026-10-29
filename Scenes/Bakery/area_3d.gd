extends Area3D

var player_nearby := false
var playing := false

@onready var prompt: Label3D = $Label3D
@onready var minigame = get_node("../PizzaPuzzle")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	minigame.finished.connect(_on_minigame_finished)
	prompt.visible = false

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		player_nearby = true
		prompt.visible = not playing

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		player_nearby = false
		prompt.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_nearby and not playing:
		playing = true
		prompt.visible = false
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		minigame.start()

func _on_minigame_finished(success: bool) -> void:
	playing = false
	get_tree().paused = false
	prompt.visible = player_nearby
	if success:
		print("Won!")
