extends Area3D

@export_file("*.tscn") var minigame_scene_path: String

@export_enum("Enostavna", "Srednje težka", "Težka")
var station_type: int = 0

@export var station_label: Label3D

var player_nearby := false

const TITLES := [
	"ENOSTAVNA POSTAJA",
	"SREDNJE TEŽKA POSTAJA",
	"TEŽKA POSTAJA"
]

const COLORS := [
	Color("#38A169"),
	Color("#E58B28"),
	Color("#E05252")
]

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if station_label:
		station_label.visible = false
		station_label.modulate = COLORS[station_type] # vsaka postaja dobi svojo barvo

	update_station_label()

# igralec dostopa lahko do postaj ko je opravil prejšnje mini igre
func is_unlocked() -> bool:
	match station_type:
		0:
			return true
		1:
			return MarketGameProgress.easy_completed
		2:
			return MarketGameProgress.medium_completed
	return false

# posodobim prikazano labelo glede na opravljenost stopenj
func update_station_label() -> void:
	if not station_label:
		return

	var message := ""

	match station_type:
		0:
			message = "Pritisni E za začetek igre"
		1:
			if is_unlocked():
				message = "Pritisni E za začetek igre"
			else:
				message = "Zaklenjeno: najprej dokončaj lahko stopnjo"
		2:
			if is_unlocked():
				message = "Pritisni E za začetek igre"
			else:
				message = "Zaklenjeno: najprej dokončaj srednjo stopnjo"

	station_label.text = TITLES[station_type] + "\n" + message

# ko uporabnik vstopi v area3d
func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		player_nearby = true
		update_station_label()
		if station_label:
			station_label.visible = true

# ko gre ven iz tega
func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		player_nearby = false
		if station_label:
			station_label.visible = false

# odločim, kaj se zgodi, ko klikne na tipko e za interact (vstopi v stopnjo)
func _process(_delta: float) -> void:
	if player_nearby:
		update_station_label()

	if player_nearby and Input.is_action_just_pressed("interact"):
		if not is_unlocked():
			return

		if minigame_scene_path != "":
			get_tree().change_scene_to_file(minigame_scene_path)
