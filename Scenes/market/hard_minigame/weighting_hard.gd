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
@onready var grape_bowl_view = $FruitTray/GrapeBowlView
@onready var check_button = $CheckButton
@onready var next_level_button = $NextLevelButton

# oznake na skledah kažejo maso enega jabolka, banane in grozda v trenutni stopnji
@onready var apple_mass_label = $FruitTray/AppleBowlView/AppleMassLabel
@onready var banana_mass_label = $FruitTray/BananaBowlView/BananaMassLabel
@onready var grape_mass_label = $FruitTray/GrapeBowlView/GrapeMassLabel

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
	banana_mass_label,
	grape_mass_label
]

const MARKET_SCENE := "res://Scenes/market/market_scene/market.tscn"

const GAME_SIZE := Vector2(1150, 650)

# navodila igre
const INFO_MARGIN := 60.0 # odmik od levega in desnega roba
const INFO_TOP := 20.0 # odmik od zgornjega roba
const INFO_FONT_SIZE := 22

# vrste sadja (uporabljene kot predpone ključev v stopnjah: apple_mass, apple_count ...)
const FRUIT_TYPES := ["apple", "banana", "grape"]

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

# grozd
const GRAPE_SCENE: PackedScene = preload(
	"res://Scenes/market/minigame_assets/grape_view.tscn"
)
const GRAPE_MIN_MASS := 100
const GRAPE_MAX_MASS := 250
const MAX_GRAPES := 5

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
const GRAPE_BOWL_LABEL_SHIFT := Vector2(0, 20)

# nagib tehtnice: koliko se nagne na gram razlike in največji nagib
const TILT_PER_GRAM := 0.0005
const MAX_TILT := 0.3

# različne merske enote
const MASS_UNITS := ["g", "dag", "kg"]

# različne stopnje
# apple_count, banana_count, grape_count = pravilna rešitev (igralcu ni povedana)
# min_fruits = sadje, za katero naročilo zahteva minimalno maso
# unit_rule = v kateri enoti je zapisan minimum: "grams" (vedno g), "different" (drugačna od enote uteži), "random" (naključna)
# hints = ali igralec ob napaki dobi namig (premalo / preveč)
# {apples}, {bananas}, {grapes} se nadomestijo z minimalno maso za to sadje
const LEVEL_TEMPLATES := [
	{
		"apple_count": 2,
		"banana_count": 1,
		"grape_count": 2,
		"min_fruits": ["grape"],
		"unit_rule": "grams",
		"hints": true,
		"story": "Lara peče sadno torto za veselico. Na vrhu mora biti vsaj {grapes} grozdja, skupna masa sadja pa mora biti enaka uteži na tehtnici. Pomagaj ji pri tehtanju, da bo torta pravočasno pripravljena!"
	},
	{
		"apple_count": 1,
		"banana_count": 3,
		"grape_count": 2,
		"min_fruits": ["banana"],
		"unit_rule": "different",
		"hints": true,
		"story": "Nogometaš Luka je po napornem treningu zelo lačen. V torbo želi pospraviti vsaj {bananas} banan, skupna masa sadja pa mora biti enaka uteži na tehtnici. Stehtaj mu sadje, saj mora še ujeti avtobus"
	},
	{
		"apple_count": 3,
		"banana_count": 2,
		"grape_count": 2,
		"min_fruits": ["apple", "grape"],
		"unit_rule": "different",
		"hints": true,
		"story": "Gostilničarka Mojca pripravlja sadni narastek za goste. Potrebuje vsaj {apples} jabolk in vsaj {grapes} grozdja, skupna masa sadja pa mora biti enaka uteži na tehtnici. Gostje že čakajo, zato ji hitro pomagaj!"
	},
	{
		"apple_count": 2,
		"banana_count": 3,
		"grape_count": 3,
		"min_fruits": ["apple", "banana", "grape"],
		"unit_rule": "different",
		"hints": true,
		"story": "Učiteljica Nina za razredni piknik pripravlja veliko sadno solato. V njej mora biti vsaj {apples} jabolk, vsaj {bananas} banan in vsaj {grapes} grozdja. Skupna masa sadja mora biti enaka uteži na tehtnici. Otroci so že nestrpni, zato pohiti z naročilom!"
	},
	{
		"apple_count": 3,
		"banana_count": 2,
		"grape_count": 4,
		"min_fruits": ["apple", "banana", "grape"],
		"unit_rule": "random",
		"hints": false,
		"story": "Teta Katica bo v nedeljo pogostila vso družino s sadnim krožnikom. Prosila te je za vsaj {apples} jabolk, vsaj {bananas} banan in vsaj {grapes} grozdja. Skupna masa sadja mora biti enaka uteži na tehtnici. To je zadnje naročilo, zato bodi natančen, saj ti tokrat ne bo povedala, kaj je narobe!"
	}
]

# položaji za največ 15 kosov sadja
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
	Vector2(1, -2),
	Vector2(-2, 0),
	Vector2(2, 0),
	Vector2(-0.5, -3),
	Vector2(0.5, -3),
	Vector2(0, -4)
]

var apples: Array[Control] = []
var bananas: Array[Control] = []
var grapes: Array[Control] = []

# osnovne mase sadja, se kasneje prepišejo
var apple_mass: int = 180
var banana_mass: int = 120
var grape_mass: int = 100

var locked: bool = false # preverim, če je preverjanje odgovora v teku (igralec med tem ne more delat nič)
var level_index: int = 0
var target_mass: int = 0 # masa uteži v gramih
var target_unit: String = "g" # enota, v kateri je masa uteži zapisana na tehtnici

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
	grape_bowl_view.gui_input.connect(_on_bowl_input.bind("grape"))

	balance_visual.set_tilt(0.3) # tehtnica ima najprej nagib na desni strani zaradi uteži

	# oznaki za mase poravnam na sredino skledic tehtnice
	for label in [left_mass_label, right_mass_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = LABEL_SIZE
		label.size = LABEL_SIZE

	_setup_bowl_label(apple_mass_label, APPLE_BOWL_LABEL_SHIFT)
	_setup_bowl_label(banana_mass_label, BANANA_BOWL_LABEL_SHIFT)
	_setup_bowl_label(grape_mass_label, GRAPE_BOWL_LABEL_SHIFT)

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

# priprava stopenj, da bo vsakič podana drugačna masa z drugačno enoto
# najprej imam pravilno rešitev (št. kosov), iz nje pa izračunam maso uteži in minimume,
func _prepare_levels() -> void:
	levels.clear()

	for template in LEVEL_TEMPLATES:
		var level: Dictionary = template.duplicate(true)

		# mase kosov izberem enkrat na stopnjo, vedno so večkratniki 10 g
		level["apple_mass"] = _random_mass(APPLE_MIN_MASS, APPLE_MAX_MASS)
		level["banana_mass"] = _random_mass(BANANA_MIN_MASS, BANANA_MAX_MASS)
		level["grape_mass"] = _random_mass(GRAPE_MIN_MASS, GRAPE_MAX_MASS)

		# masa uteži = masa pravilne rešitve, zapisana v naključni enoti
		var total := 0
		
		for fruit_type in FRUIT_TYPES:
			total += int(level[fruit_type + "_count"]) * int(level[fruit_type + "_mass"])

		level["target_mass"] = total
		level["target_unit"] = _random_mass_unit()

		# minimum za posamezno sadje, rešitev ga mora izpolnjevati, vendar je minimum višji od mase (št. kosov - 1)
		# igralec potrebuje vsaj toliko kosov kot rešitev
		for fruit_type in level["min_fruits"]:
			var fruit_mass: int = int(level[fruit_type + "_mass"])
			var order_mass: int = int(level[fruit_type + "_count"]) * fruit_mass
			var extra: int = _random_mass(roundi(fruit_mass / 2.0), fruit_mass)

			level[fruit_type + "_min"] = order_mass - fruit_mass + extra
			level[fruit_type + "_min_unit"] = _minimum_unit(
				str(level["unit_rule"]),
				str(level["target_unit"])
			)
		levels.append(level)

# naključna masa med min in max, zaokrožena na večkratnik MASS_STEP
func _random_mass(min_mass: int, max_mass: int) -> int:
	var low: int = ceili(min_mass / float(MASS_STEP))
	var high: int = floori(max_mass / float(MASS_STEP))

	return rng.randi_range(low, high) * MASS_STEP

func _random_mass_unit() -> String:
	return MASS_UNITS[rng.randi_range(0, MASS_UNITS.size() - 1)]

# enota minimuma glede na pravilo stopnje
func _minimum_unit(rule: String, weight_unit: String) -> String:
	match rule:
		"grams":
			return "g"
		"different":
			var units: Array = MASS_UNITS.duplicate()
			units.erase(weight_unit) # enota minimuma je drugačna od enote uteži
			
			return units[rng.randi_range(0, units.size() - 1)]
		_:
			return _random_mass_unit()

# kilogrami kot besedilo z vejico, da ni nepotrebnih ničel
func _kg_text(grams: int) -> String:
	var kg := "%.2f" % (grams / 1000.0)
	return kg.rstrip("0").rstrip(".").replace(".", ",")

# kratek izpis mase z enoto za napis na tehtnici
func _format_mass(grams: int, unit: String) -> String:
	match unit:
		"dag":
			return "%d dag" % roundi(grams / 10.0)
		"kg":
			return "%s kg" % _kg_text(grams)
		_:
			return "%d g" % grams

# izpis enot z besedo in preračun iz gramov za besedilo zgodbe
func _mass_words(grams: int, unit: String) -> String:
	match unit:
		"dag":
			return "%d dekagramov" % roundi(grams / 10.0)
		"kg":
			return "%s kilogramov" % _kg_text(grams)
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
	grape_mass = int(level["grape_mass"])

	target_mass = int(level["target_mass"])
	target_unit = str(level["target_unit"])

	_clear_fruit()

	locked = false
	check_button.visible = false
	next_level_button.visible = false

	# oznake mase na skledah, spremenijo se v naslednji stopnji
	apple_mass_label.text = "%d g" % apple_mass
	banana_mass_label.text = "%d g" % banana_mass
	grape_mass_label.text = "%d g" % grape_mass

	# v zgodbo vstavim minimalne mase za sadje iz naročila (npr. {grapes}) v njihovih enotah
	var story_values := {}
	
	for fruit_type in level["min_fruits"]:
		story_values[fruit_type + "s"] = _mass_words(
			int(level[fruit_type + "_min"]),
			str(level[fruit_type + "_min_unit"])
		)
	info_label.text = String(level["story"]).format(story_values)

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

	for fruit in grapes:
		fruit.queue_free()

	apples.clear()
	bananas.clear()
	grapes.clear()

func _on_next_level_pressed() -> void:
	if level_index < levels.size() - 1:
		level_index += 1
		load_level()
	else:
		MarketGameProgress.hard_completed = true
		level_completed.emit()
		go_to_market()

# dodam sadje v skledo z levim klikom
func _is_left_click(event: InputEvent) -> bool:
	return (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT
	)

# klik na skledo, da se doda sadje (fruit_type pride iz bind: apple, banana ali grape)
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
		"grape":
			if grapes.size() >= MAX_GRAPES:
				return
			fruit_scene = GRAPE_SCENE
			fruit_list = grapes
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
func _on_placed_fruit_input(event: InputEvent, fruit: Control, fruit_list: Array[Control]) -> void:
	if locked or not _is_left_click(event):
		return

	fruit_list.erase(fruit)
	fruit.queue_free()
	update_balance()

# seznam sadja na tehtnici glede na vrsto
func _fruit_list(fruit_type: String) -> Array[Control]:
	match fruit_type:
		"apple":
			return apples
		"banana":
			return bananas
		_:
			return grapes

# masa enega kosa glede na vrsto sadja
func _fruit_mass(fruit_type: String) -> int:
	match fruit_type:
		"apple":
			return apple_mass
		"banana":
			return banana_mass
		_:
			return grape_mass

# skupna masa sadja na tehtnici v gramih
func _current_mass() -> int:
	return (
		apples.size() * apple_mass
		+ bananas.size() * banana_mass
		+ grapes.size() * grape_mass
	)

# preverim, če so izpolnjeni vsi minimumi iz naročila
func _minimums_met(level: Dictionary) -> bool:
	for fruit_type in level["min_fruits"]:
		var mass_on_balance: int = _fruit_list(fruit_type).size() * _fruit_mass(fruit_type)

		if mass_on_balance < int(level[fruit_type + "_min"]):
			return false

	return true

# preverim, če je naročilo pravilno pripravljeno
func _on_check_pressed() -> void:
	locked = true
	check_button.visible = false

	var level: Dictionary = levels[level_index]
	var left_mass: int = _current_mass()

	# naročilo je pravilno, če je masa enaka uteži in so izpolnjeni vsi minimumi
	var correct_mass: bool = left_mass == target_mass
	var correct_minimums: bool = _minimums_met(level)

	if correct_mass and correct_minimums:
		if level_index == levels.size() - 1:
			info_label.text = (
				"Odlično! Vsa naročila so uspešno pripravljena! "
				+ "Klikni \"Končaj\" in se vrni v trgovino."
			)
		else:
			info_label.text = (
				"Odlično! Naročilo je pravilno pripravljeno in tehtnica je "
				+ "v ravnovesju. Klikni \"Naslednja stopnja\" za nadaljevanje."
			)
		next_level_button.visible = true
		return

	# v zadnji stopnji igralec ne dobi namiga, kaj je narobe
	if not bool(level["hints"]):
		info_label.text = (
			"Naročilo ni pravilno pripravljeno. "
			+ "Preveri maso in pogoje ter poskusi znova!"
		)
	elif left_mass < target_mass:
		info_label.text = (
			"Na tehtnici je premalo sadja. Poskusi znova!"
		)
	elif left_mass > target_mass:
		info_label.text = (
			"Na tehtnici je preveč sadja. Poskusi znova!"
		)
	else:
		info_label.text = (
			"Skupna masa je prava, vendar naročilo zahteva več določenega sadja. "
			+ "Preveri pogoje in poskusi znova!"
		)

	await get_tree().create_timer(RESET_DELAY).timeout

	# po napačnem odgovoru znova naložim isto stopnjo (če igralec medtem ni zapustil scene)
	if is_inside_tree():
		load_level()

# posodobim oznake mase, vidnost gumba za preverjanje pa nagib tehtnice
func update_balance() -> void:
	var left_mass: int = _current_mass()

	# levo je vedno v gramih, desno pa v enoti, ki jo določa stopnja
	left_mass_label.text = "%d g" % left_mass
	right_mass_label.text = _format_mass(target_mass, target_unit)

	check_button.visible = (apples.size() + bananas.size() + grapes.size()) > 0 and not locked

	# izračunam ciljni nagib glede na razliko med masama (clampf mi omeji nagib)
	var target_tilt := clampf(		float(target_mass - left_mass) * TILT_PER_GRAM, -MAX_TILT, MAX_TILT)
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

	# najprej razporedim jabolka, nato banane in grozde na preostale položaje
	slot_index = _place_fruit_list(apples, slot_index, base)
	slot_index = _place_fruit_list(bananas, slot_index, base)
	_place_fruit_list(grapes, slot_index, base)

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
