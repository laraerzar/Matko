extends Area3D

# ključ planeta v game_state.gd (PLANETS)
@export var planet_id: String = "merske_enote"

@onready var blocker: CollisionShape3D = $"../GateBlocker/CollisionShape3D"
@onready var route_layer: CanvasLayer = $"../RouteMapLayer"
@onready var route_map = $"../RouteMapLayer/RouteMap"

var opened: bool = false # da se zemljevid ne odpre dvakrat

func _ready() -> void:
	route_layer.visible = false
	body_entered.connect(_on_body_entered)
	route_map.travel_requested.connect(_on_travel_requested)
	_update_gate()

# vrata so zaprta, dokler niso opravljene vse tri postaje
func _update_gate() -> void:
	blocker.set_deferred("disabled", MarketGameProgress.all_completed())

# igralec je šel skozi vrata, planet je končan, pokažem zemljevid poti
func _on_body_entered(body: Node3D) -> void:
	if opened or not body is CharacterBody3D or not MarketGameProgress.all_completed():
		return
	opened = true

	# TEST: simuliram, da je bil prvi planet že opravljen
	if not GameState.is_completed("stevila"):
		GameState.completed_planets.append("stevila")

	# tržnico označim kot opravljeno
	if not GameState.is_completed(planet_id):
		GameState.completed_planets.append(planet_id)

	# igralec med izbiro ne more hoditi, miška mora biti vidna
	if body.has_method("set_frozen"):
		body.set_frozen(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	route_map.refresh()
	route_layer.visible = true

# klik na "Odpotuj" pri planetu
func _on_travel_requested(next_planet_id: String) -> void:
	route_layer.visible = false
	GameState.go_to_planet(next_planet_id)
