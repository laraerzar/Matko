extends Area3D

@export_file("*.tscn") var minigame_scene_path: String

var player_nearby := false

@onready var prompt: Label3D = $"../../InteractionPromptMarket"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.visible = false

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		player_nearby = true
		prompt.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		player_nearby = false
		prompt.visible = false

func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		if minigame_scene_path != "":
			get_tree().change_scene_to_file(minigame_scene_path)
