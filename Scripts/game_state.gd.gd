extends Node

const STATION_SCENE: String = "res://Scenes/space_station/space_station.tscn"
const PLACEHOLDER_SCENE: String = "res://Scenes/placeholder_planet.tscn"
const ENDING_SCENE: String = "res://Scenes/ending.tscn"

const PLANET_ORDER: Array[String] = ["stevila", "merske_enote", "ulomki"]

# Poti do scen planetov
const PLANETS: Dictionary = {
	"stevila": {
		"name": "Planet števil",
		"desc": "Števila in računanje",
		"texture": "res://Assets/Sprites/planets/planet06.png",
		"scene": "res://Scenes/planet_stevila.tscn",
	},
	"merske_enote": {
		"name": "Planet merskih enot",
		"desc": "Tržnica in tehtnica",
		"texture": "res://Assets/Sprites/planets/planet09.png",
		"scene": "res://Scenes/market.tscn",
	},
	"ulomki": {
		"name": "Planet ulomkov",
		"desc": "Pekarna prijatelja",
		"texture": "res://Assets/Sprites/planets/planet02.png",
		"scene": "res://Scenes/planet_ulomki.tscn",
	},
}

var completed_planets: Array[String] = []
var total_mistakes: int = 0
var current_planet: String = "stevila"

func planet_name(id: String) -> String:
	if PLANETS.has(id):
		return PLANETS[id]["name"]
	return "Konec igre"

func is_completed(id: String) -> bool:
	return id in completed_planets

func next_planet() -> String:
	for id in PLANET_ORDER:
		if not is_completed(id):
			return id
	return ""

func is_next(id: String) -> bool:
	return id == next_planet()

func station_visit() -> int:
	return clampi(completed_planets.size(), 1, 2)

func start_game() -> void:
	completed_planets.clear()
	total_mistakes = 0
	go_to_planet(PLANET_ORDER[0])

func go_to_planet(id: String) -> void:
	current_planet = id
	_change_scene(PLANETS[id]["scene"])

# to pokliče vsak planet, ko je opravljen.
func finish_planet(id: String, mistakes: int) -> void:
	if not is_completed(id):
		completed_planets.append(id)
	total_mistakes += mistakes
	if next_planet() == "":
		current_planet = ""
		_change_scene(ENDING_SCENE)
	else:
		_change_scene(STATION_SCENE)

func _change_scene(path: String) -> void:
	var target := path
	if not ResourceLoader.exists(path):
		push_warning("Scena ne obstaja, nalagam začasno: " + path)
		target = PLACEHOLDER_SCENE
	get_tree().change_scene_to_file(target)
