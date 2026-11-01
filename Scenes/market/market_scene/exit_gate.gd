extends Area3D

# ključ planeta v game_state.gd (PLANETS)
@export var planet_id: String = "merske_enote"

@onready var blocker: CollisionShape3D = $"../GateBlocker/CollisionShape3D"

var finished: bool = false # da se planet ne zaključi dvakrat

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_gate()

# vrata so zaprta, dokler niso opravljene vse tri postaje
func _update_gate() -> void:
	blocker.set_deferred("disabled", MarketGameProgress.all_completed())

# igralec je šel skozi vrata, planet je končan, vrnem se na vesoljsko postajo
func _on_body_entered(body: Node3D) -> void:
	if finished or not body is CharacterBody3D or not MarketGameProgress.all_completed():
		return
	finished = true
	
	GameState.call_deferred("finish_planet", planet_id, 0)
