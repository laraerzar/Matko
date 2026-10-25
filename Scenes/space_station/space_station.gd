extends Node3D

@onready var puzzle_layer: CanvasLayer = $PuzzleLayer
@onready var puzzle = $PuzzleLayer/TimePuzzle
@onready var terminal: Area3D = $Terminal
@onready var player: CharacterBody3D = $Player
@onready var hint_label: Label3D = get_node_or_null("Terminal/Label3D")
@onready var guide: Node3D = $Terminal/Guide
@onready var arrow: Node3D = $Terminal/Guide/Arrow
@onready var intro_layer: CanvasLayer = $IntroLayer
@onready var intro_text: Label = $IntroLayer/Margin/Box/VBox/IntroText
@onready var route_layer: CanvasLayer = $RouteMapLayer
@onready var route_map = $RouteMapLayer/RouteMap
@onready var ships: Node3D = $Room/Ships

# Za testiranje postaje samo zase (F6): kateri obisk naj simulira.
@export_range(1, 2) var debug_visit: int = 1

var intro_by_visit: Dictionary = {
	1: [
		"Matko: Računalnik je popravljen! Zdaj lahko kupim vozovnico za tržnico.",
		"Premikaj se s puščicami ali WASD. Pritisni E ob računalniku.",
	],
	2: [
		"Matko: Zdaj pa še zadnja vozovnica, do prijatelja!",
		"Pritisni E ob računalniku.",
	],
}

# Težavnost vsakega vprašanja: 0 Lahko, 1 Srednje, 2 Težko, 3 Potovanje
var plan_by_visit: Dictionary = {
	1: [0, 0, 1, 1, 1],
	2: [2, 2, 3, 3, 3],
}

var visit: int = 1
var intro_lines: Array[String] = []
var intro_index: int = 0
var intro_active: bool = false

var player_near: bool = false
var puzzle_open: bool = false
var solved: bool = false
var arrow_tween: Tween

func _ready() -> void:
	# Če postajo zaženeš samo zase, simuliraj, da je bil prejšnji planet opravljen.
	if GameState.completed_planets.is_empty():
		for i in debug_visit:
			GameState.completed_planets.append(GameState.PLANET_ORDER[i])
	visit = GameState.station_visit()

	puzzle_layer.visible = false
	route_layer.visible = false
	terminal.body_entered.connect(_on_body_entered)
	terminal.body_exited.connect(_on_body_exited)
	puzzle.puzzle_completed.connect(_on_puzzle_completed)
	route_map.travel_requested.connect(_on_travel_requested)
	start_arrow_bounce()
	show_intro()

# ---------- uvod ----------

func show_intro() -> void:
	intro_lines.assign(intro_by_visit[visit])
	intro_active = true
	intro_index = 0
	intro_text.text = intro_lines[0]
	intro_layer.visible = true
	player.set_frozen(true)

func advance_intro() -> void:
	intro_index += 1
	if intro_index >= intro_lines.size():
		intro_active = false
		intro_layer.visible = false
		player.set_frozen(false)
	else:
		intro_text.text = intro_lines[intro_index]

# ---------- puščica ----------

func start_arrow_bounce() -> void:
	var base_y := arrow.position.y
	arrow_tween = create_tween().set_loops()
	arrow_tween.tween_property(arrow, "position:y", base_y + 0.4, 0.6) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	arrow_tween.tween_property(arrow, "position:y", base_y, 0.6) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ---------- območje terminala ----------

func set_hint_visible(value: bool) -> void:
	if hint_label != null:
		hint_label.visible = value

func _on_body_entered(body: Node3D) -> void:
	if body == player:
		player_near = true
		set_hint_visible(not solved)

func _on_body_exited(body: Node3D) -> void:
	if body == player:
		player_near = false
		set_hint_visible(false)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if intro_active:
		if event.physical_keycode == KEY_SPACE or event.physical_keycode == KEY_ENTER:
			advance_intro()
		return
	if event.physical_keycode == KEY_E and player_near and not puzzle_open and not solved:
		open_puzzle()
	elif event.physical_keycode == KEY_ESCAPE and puzzle_open:
		close_puzzle()

# ---------- uganka ----------

func open_puzzle() -> void:
	puzzle_open = true
	set_hint_visible(false)
	player.set_frozen(true)
	puzzle_layer.visible = true
	puzzle.set_plan(plan_by_visit[visit])

func close_puzzle() -> void:
	puzzle_open = false
	puzzle_layer.visible = false
	player.set_frozen(false)

func _on_puzzle_completed(mistakes: int) -> void:
	solved = true
	guide.visible = false
	GameState.total_mistakes += mistakes
	await get_tree().create_timer(1.5).timeout
	close_puzzle()
	show_route_map()

# ---------- zemljevid poti in odhod ----------

func show_route_map() -> void:
	player.set_frozen(true)
	route_map.refresh()
	route_layer.visible = true

func _on_travel_requested(planet_id: String) -> void:
	route_layer.visible = false
	await matko_boards()
	await ship_departs(planet_id)
	GameState.go_to_planet(planet_id)
	
func matko_boards() -> void:
	var model := player.get_node_or_null("Matko") as Node3D
	if model == null:
		return
	var tween := create_tween()
	tween.tween_property(model, "scale", Vector3.ZERO, 0.4) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	model.visible = false

func ship_departs(planet_id: String) -> void:
	var index := GameState.PLANET_ORDER.find(planet_id)
	if index < 0 or index >= ships.get_child_count():
		return
	var ship := ships.get_child(index) as Node3D
	if ship == null:
		return
	var tween := create_tween()
	tween.tween_property(ship, "position:y", ship.position.y + 3.0, 1.0)
	tween.tween_property(ship, "position:z", ship.position.z - 80.0, 2.5) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
