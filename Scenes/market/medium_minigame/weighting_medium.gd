extends Control

signal level_completed # sproži se po zadnji stopnji

# reference na elemente ui
@onready var instructions_panel = $InstructionsPanel
@onready var start_button = $InstructionsPanel/InstructionsContent/StartButton
@onready var back_button = $BackButton

@onready var balance_visual = $BalanceVisual
@onready var fruit_tray = $FruitTray
@onready var apple_bowl_view = $FruitTray/AppleBowlView
@onready var banana_bowl_view = $FruitTray/BananaBowlView
@onready var check_button = $CheckButton
@onready var next_level_button = $NextLevelButton

# oznaki na skledah kažeta maso enega jabolka in banane v trenutni stopnji
@onready var apple_mass_label = $FruitTray/AppleBowlView/AppleMassLabel
@onready var banana_mass_label = $FruitTray/BananaBowlView/BananaMassLabel

@onready var left_mass_label = $LeftMassLabel
@onready var right_mass_label = $RightMassLabel
@onready var info_label = $InfoLabel

# vsi elementi, ki se prikažejo komaj po kliku na gumb Začni
@onready var game_nodes: Array[CanvasItem] = [
	balance_visual,
	fruit_tray,
	left_mass_label,
	right_mass_label,
	info_label,
	back_button,
	apple_mass_label,
	banana_mass_label
]

const MARKET_SCENE := "res://Scenes/market/market_scene/market.tscn"

const GAME_SIZE := Vector2(1150, 650)

# navodila igre
const INFO_MARGIN := 60.0 # odmik od levega in desnega roba
const INFO_TOP := 20.0 # odmik od zgornjega roba
const INFO_FONT_SIZE := 22

# jabolko
const APPLE_SCENE: PackedScene = preload(
	"res://Scenes/market/minigame_assets/apple_view.tscn"
)
const APPLE_MIN_MASS := 150
const APPLE_MAX_MASS := 200
const MAX_APPLES := 5

# banana
const BANANA_SCENE: PackedScene = preload(
	"res://Scenes/market/minigame_assets/banana_view.tscn"
)
const BANANA_MIN_MASS := 80
const BANANA_MAX_MASS := 150
const MAX_BANANAS := 5

# razponi mas v gramih, vedno so večkratniki števila MASS_STEP
const MASS_STEP := 10
const FRUIT_SIZE := 60.0
const FRUIT_OFFSET := Vector2(-20, 0)

# oznake za maso
const LABEL_SIZE := Vector2(120, 40)
const LABEL_BOWL_OFFSET := 30.0

# delay po napačnem odgovoru, uporabnik lahko v miru prebere kaj je blo narobe
const RESET_DELAY := 3.0

# premik oznake na skledi glede na sredino sklede
const APPLE_BOWL_LABEL_SHIFT := Vector2(0, 10)
const BANANA_BOWL_LABEL_SHIFT := Vector2(0, 20)

const TILT_PER_GRAM := 0.0005
const MAX_TILT := 0.3

# različne merske enote
const MASS_UNITS := ["g", "dag", "kg"]

# različne stopnje ({apples} in {bananas} se nadomestita z masama naročila)
const LEVEL_TEMPLATES := [
	{
		"apple_count": 1,
		"banana_count": 2,
		"story": "Simona si pripravlja sadno kupo. Zanjo potrebuje {apples} jabolk ter {bananas} banan. Prosila te je, da ji pomagaš pri tehtanju sadja, saj se ji mudi."
	},
	{
		"apple_count": 2,
		"banana_count": 1,
		"story": "Martin je med odmorom prišel po zdravo malico. Zaželel si je {apples} jabolk ter {bananas} banan. Pripravi mu naročilo!"
	},
	{
		"apple_count": 3,
		"banana_count": 2,
		"story": "Kmet Bine želi svojim kokoškam pripraviti poslastico. Prosil te je, da mu stehtaš {apples} jabolk ter {bananas} banan. Stehtaj sadje za lačne kokoške!"
	},
	{
		"apple_count": 1,
		"banana_count": 4,
		"story": "Mami te je poklicala po telefonu. Prosila te je, da ji kupiš {apples} jabolk ter {bananas} banan, saj ti želi speči tvoje najljubše pecivo, ko se vrneš domov. Pripravi si naročilo!"
	},
	{
		"apple_count": 4,
		"banana_count": 4,
		"story": "Prijatelju si obljubil, da mu naslednjič prineseš nekaj za malico. Zaželel si je {apples} jabolk ter {bananas} banan. Stehtaj naročilo in ga preseneti!"
	}
]

# položaji za največ 10 kosov sadja
const SLOTS := [
	Vector2(0, 0),
	Vector2(1, 0),
	Vector2(-1, 0),
	Vector2(-0.5, -1),
	Vector2(0.5, -1),
	Vector2(0, -2),
	Vector2(-1.5, -1),
	Vector2(1.5, -1),
	Vector2(-1, -2),
	Vector2(1, -2)
]

var apples: Array[Control] = []
var bananas: Array[Control] = []

# osnovne mase sadja, se kasneje prepišejo
var apple_mass: int = 180
var banana_mass: int = 120

var locked: bool = false # preverim, če je preverjanje odgovora v teku (igralec med tem ne more delat nič)
var level_index: int = 0
var target_mass: int = 0

var levels: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

# izvedem, ko je scena pripravljena
func _ready() -> void:
	set_process(false)

	rng.randomize()
	_prepare_levels()

	instructions_panel.visible = true
	check_button.visible = false
	next_level_button.visible = false

	for node in game_nodes:
		node.visible = false

	start_button.pressed.connect(start_game)
	back_button.pressed.connect(go_to_market)
	check_button.pressed.connect(_on_check_pressed)
	next_level_button.pressed.connect(_on_next_level_pressed)
	apple_bowl_view.gui_input.connect(_on_bowl_input.bind("apple"))
	banana_bowl_view.gui_input.connect(_on_bowl_input.bind("banana"))

	balance_visual.set_tilt(0.3) # tehtnica ima najprej nagib na desni strani zaradi uteži

	# oznake za mase poravnam na sredino skledic tehtnice
	for label in [left_mass_label, right_mass_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = LABEL_SIZE
		label.size = LABEL_SIZE

	_setup_bowl_label(apple_mass_label, APPLE_BOWL_LABEL_SHIFT)
	_setup_bowl_label(banana_mass_label, BANANA_BOWL_LABEL_SHIFT)

	# položaj besedila z navodili
	info_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	info_label.position = Vector2(INFO_MARGIN, INFO_TOP)
	info_label.custom_minimum_size = Vector2(GAME_SIZE.x - INFO_MARGIN * 2.0, 0)
	info_label.size = Vector2(GAME_SIZE.x - INFO_MARGIN * 2.0, 0)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_label.add_theme_font_size_override("font_size", INFO_FONT_SIZE)

	update_mass_label_positions()

# oznaka mase sadja v skledi
func _setup_bowl_label(label: Label, shift: Vector2) -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left += shift.x
	label.offset_right += shift.x
	label.offset_top += shift.y
	label.offset_bottom += shift.y

# priprava levlov, da bo vsakič podana drugačna masa z drugačno enoto
func _prepare_levels() -> void:
	levels.clear()

	for template in LEVEL_TEMPLATES:
		var level: Dictionary = template.duplicate(true)

		# masi izberem enkrat na stopnjo, vedno sta večkratnika 10
		level["apple_mass"] = _random_mass(APPLE_MIN_MASS, APPLE_MAX_MASS)
		level["banana_mass"] = _random_mass(BANANA_MIN_MASS, BANANA_MAX_MASS)

		level["apple_unit"] = _random_mass_unit()
		level["banana_unit"] = _random_mass_unit()

		levels.append(level)

# naključna masa med min in max, zaokrožena na večkratnik MASS_STEP
func _random_mass(min_mass: int, max_mass: int) -> int:
	var low: int = ceili(min_mass / float(MASS_STEP))
	var high: int = floori(max_mass / float(MASS_STEP))
	
	return rng.randi_range(low, high) * MASS_STEP

func _random_mass_unit() -> String:
	return MASS_UNITS[rng.randi_range(0, MASS_UNITS.size() - 1)]

# izpis enot z besedo in preračun iz gramov
func _mass_words(grams: int, unit: String) -> String:
	match unit:
		"dag":
			return "%d dekagramov" % roundi(grams / 10.0)
		"kg":
			var kg := "%.2f" % (grams / 1000.0)
			kg = kg.rstrip("0").replace(".", ",")  # 0,50 -> 0,5
			return "%s kilogramov" % kg
		_:
			return "%d gramov" % grams

func start_game() -> void:
	instructions_panel.visible = false

	for node in game_nodes:
		node.visible = true

	set_process(true)
	level_index = 0
	load_level()

func load_level() -> void:
	var level: Dictionary = levels[level_index]

	apple_mass = int(level["apple_mass"])
	banana_mass = int(level["banana_mass"])

	var apple_count: int = int(level["apple_count"])
	var banana_count: int = int(level["banana_count"])
	var apple_order_mass: int = apple_count * apple_mass
	var banana_order_mass: int = banana_count * banana_mass

	target_mass = apple_order_mass + banana_order_mass

	_clear_fruit()

	locked = false
	check_button.visible = false
	next_level_button.visible = false

	# oznaki mase na skledah, spremenita se v naslednji stopnji
	apple_mass_label.text = "%d g" % apple_mass
	banana_mass_label.text = "%d g" % banana_mass

	# v zgodbo vstavim maso naročenih jabolk in banan v naključni enoti
	info_label.text = String(level["story"]).format({
		"apples": _mass_words(apple_order_mass, str(level["apple_unit"])),
		"bananas": _mass_words(banana_order_mass, str(level["banana_unit"]))
	})

	# v zadnji stopnji gumbek izpiše "Končaj"
	if level_index == levels.size() - 1:
		next_level_button.text = "Končaj"
	else:
		next_level_button.text = "Naslednja stopnja"

	update_balance()

func _clear_fruit() -> void:
	for fruit in apples:
		fruit.queue_free()
		
	for fruit in bananas:
		fruit.queue_free()

	apples.clear()
	bananas.clear()

func _on_next_level_pressed() -> void:
	if level_index < levels.size() - 1:
		level_index += 1
		load_level()
	else:
		MarketGameProgress.medium_completed = true
		level_completed.emit()
		go_to_market()

# dodam sadje v skledo z levim klikom
func _is_left_click(event: InputEvent) -> bool:
	return (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT
	)

# klik na skledo, da se doda sadje (fruit_type pride iz bind apple ali banana)
func _on_bowl_input(event: InputEvent, fruit_type: String) -> void:
	if _is_left_click(event):
		add_fruit(fruit_type)

func add_fruit(fruit_type: String) -> void:
	if locked:
		return

	var fruit_scene: PackedScene
	var fruit_list: Array[Control]

	# glede na vrsto sadja izberem sceno in seznam, hkrati omejim število kosov
	match fruit_type:
		"apple":
			if apples.size() >= MAX_APPLES:
				return
			fruit_scene = APPLE_SCENE
			fruit_list = apples
		"banana":
			if bananas.size() >= MAX_BANANAS:
				return
			fruit_scene = BANANA_SCENE
			fruit_list = bananas
		_:
			return

	var fruit := fruit_scene.instantiate() as Control
	fruit.scale = Vector2.ONE
	fruit.custom_minimum_size = Vector2(FRUIT_SIZE, FRUIT_SIZE)
	fruit.size = Vector2(FRUIT_SIZE, FRUIT_SIZE)
	fruit.show_behind_parent = true

	fruit.gui_input.connect(_on_placed_fruit_input.bind(fruit, fruit_list))

	balance_visual.add_child(fruit)
	fruit_list.append(fruit)

	update_balance()

# odstranjevanje sadja
func _on_placed_fruit_input(
	event: InputEvent,
	fruit: Control,
	fruit_list: Array[Control]
) -> void:
	if locked or not _is_left_click(event):
		return

	fruit_list.erase(fruit)
	fruit.queue_free()
	update_balance()

# skupna masa sadja na tehtnici v gramih
func _current_mass() -> int:
	return apples.size() * apple_mass + bananas.size() * banana_mass

# preverim, če je naročilo pravilno pripravljeno
func _on_check_pressed() -> void:
	locked = true
	check_button.visible = false

	var level: Dictionary = levels[level_index]
	var left_mass: int = _current_mass()

	# naročilo je pravilno, če je tudi število jabolk in banan pravilno
	var correct_counts: bool = (
		apples.size() == int(level["apple_count"])
		and bananas.size() == int(level["banana_count"])
	)
	if correct_counts:
		if level_index == levels.size() - 1:
			info_label.text = (
				"Odlično! Vsa naročila so uspešno pripravljena! "
				+ "Klikni \"Končaj\" in se pomeri še v najtežjem izzivu."
			)
		else:
			info_label.text = (
				"Odlično! Naročilo je pravilno pripravljeno in tehtnica je "
				+ "v ravnovesju. Klikni \"Naslednja stopnja\" za nadaljevanje."
			)
		next_level_button.visible = true
		return

	if left_mass < target_mass:
		info_label.text = (
			"Na tehtnici je premalo sadja. Poskusi znova!"
		)
	elif left_mass > target_mass:
		info_label.text = (
			"Na tehtnici je preveč sadja. Poskusi znova!"
		)
	else:
		info_label.text = (
			"Skupna masa je prava, vendar število jabolk ali banan ni pravilno. "
			+ "Preveri naročilo in poskusi znova!"
		)

	await get_tree().create_timer(RESET_DELAY).timeout

	# po napačnem odgovoru znova naložim isto stopnjo (če igralec medtem ni zapustil scene)
	if is_inside_tree():
		load_level()

# posodobim oznake mase, vidnost gumba za preverjanje pa nagib tehtnice
func update_balance() -> void:
	var left_mass: int = _current_mass()

	left_mass_label.text = "%d g" % left_mass
	right_mass_label.text = "%d g" % target_mass

	check_button.visible = (apples.size() + bananas.size()) > 0 and not locked

	# izračunam ciljni nagib glede na razliko med masama (clampf mi omeji nagib)
	var target_tilt := clampf(
		float(target_mass - left_mass) * TILT_PER_GRAM,
		-MAX_TILT,
		MAX_TILT
	)
	balance_visual.animate_tilt(target_tilt)

# s tem posodobim pozicijo oznak mase glede na trenutni položaj tehtnice
func update_mass_label_positions() -> void:
	var offset := Vector2(0, LABEL_BOWL_OFFSET)
	var origin: Vector2 = balance_visual.global_position

	left_mass_label.global_position = (
		origin + balance_visual.get_left_pan_pos() + offset - LABEL_SIZE / 2.0
	)
	right_mass_label.global_position = (
		origin + balance_visual.get_right_pan_pos() + offset - LABEL_SIZE / 2.0
	)

func go_to_market() -> void:
	get_tree().change_scene_to_file(MARKET_SCENE)

func _process(_delta: float) -> void:
	update_mass_label_positions()

	var base: Vector2 = balance_visual.get_left_pan_pos()
	var slot_index := 0

	# najprej razporedim jabolka, banane pa na preostale položaje
	slot_index = _place_fruit_list(apples, slot_index, base)
	_place_fruit_list(bananas, slot_index, base)

# postavi sadje na položaje SLOTS in vrne naslednji prosti indeks
func _place_fruit_list(list: Array[Control], start: int, base: Vector2) -> int:
	var index := start

	for fruit in list:
		var slot: Vector2 = SLOTS[index]

		var spot := base + Vector2(
			slot.x * FRUIT_SIZE * 0.85,
			slot.y * FRUIT_SIZE * 0.75
		)
		fruit.position = (
			spot
			- Vector2(FRUIT_SIZE / 2.0, FRUIT_SIZE * 0.7)
			+ FRUIT_OFFSET
		)
		index += 1

	return index
