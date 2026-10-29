extends Control

signal level_completed # sproži se po zadnji stopnji

# reference na elemente ui
@onready var instructions_panel = $InstructionsPanel
@onready var start_button = $InstructionsPanel/InstructionsContent/StartButton
@onready var back_button = $BackButton

@onready var balance_visual = $BalanceVisual
@onready var fruit_tray = $FruitTray
@onready var apple_bowl_view = $FruitTray/AppleBowlView
@onready var check_button = $CheckButton
@onready var next_level_button = $NextLevelButton

@onready var left_mass_label = $LeftMassLabel
@onready var right_mass_label = $RightMassLabel
@onready var info_label = $InfoLabel
@onready var one_apple_mass_label = $AppleMassLabel

# vsi elementi, ki se prikažejo komaj po kliku na gumb Začni
@onready var game_nodes = [
	balance_visual,
	fruit_tray,
	left_mass_label,
	right_mass_label,
	one_apple_mass_label,
	info_label,
	back_button
]

const MARKET_SCENE := "res://Scenes/market/market_scene/market.tscn"

const GAME_SIZE := Vector2(1150, 650)

# navodila igre
const INFO_MARGIN := 60.0 # odmik od levega in desnega roba
const INFO_TOP := 20.0 # odmik od zgornjega roba
const INFO_FONT_SIZE := 22

# jabolko
const APPLE_SCENE := preload("res://Scenes/market/minigame_assets/apple_view.tscn")
const APPLE_SIZE := 60.0
const APPLE_OFFSET := Vector2(-20, 0) # odmik jabolka na tehtnici
const APPLE_MASS := 200
const MAX_APPLES := 6

# oznake za maso
const LABEL_SIZE := Vector2(120, 40)
const LABEL_BOWL_OFFSET := 30.0

# delay po napačnem odgovoru, uporabnik lahko v miru prebere kaj je blo narobe
const RESET_DELAY := 3.0

# različne stopnje (%d je za maso uteži)
const LEVELS := [
	{
		"mass": 600,
		"story": "Marta želi speči jabolčno pito, vendar ji je zmanjkalo %d gramov jabolk. Pomagaj Matku pripraviti sadno naročilo!",
	},
	{
		"mass": 400,
		"story": "Tine kuha jabolčni kompot za zimo. Za pripravo potrebuje natanko %d gramov jabolk. Pomagaj mu jih odmeriti!",
	},
	{
		"mass": 1200,
		"story": "Na tržnici je kmetu Janezu zmanjkalo jabolk za zadnje naročilo. Prosil te je, če mu oddaš %d gramov jabolk. Pomagaj mu dokončati naročilo!",
	},
	{
		"mass": 800,
		"story": "Babica Ana peče jabolčni štrudelj za vso družino. Recept pravi, da potrebuje %d gramov jabolk. Koliko jabolk mora dati na tehtnico?",
	},
	{
		"mass": 1000,
		"story": "V vrtcu pripravljajo sadni krožnik za malico. Vzgojiteljica potrebuje %d gramov jabolk, da bo dovolj za vse otroke. Pripravi še zadnje naročilo!",
	}
]

# položaji jabolk na tehtnici za lepši izgled
const SLOTS := [
	Vector2(0, 0),
	Vector2(1, 0),
	Vector2(-1, 0),
	Vector2(-0.5, -1),
	Vector2(0.5, -1),
	Vector2(0, -2),
]

var apples: Array = []
var locked := false # preverim, če je preverjanje odgovora v teku (igralec med tem ne more delat nič)
var level_index := 0
var target_mass := 0

# izvedem, ko je scena pripravljena
func _ready() -> void:
	instructions_panel.visible = true
	check_button.visible = false
	next_level_button.visible = false
	
	for node in game_nodes:
		node.visible = false

	start_button.pressed.connect(start_game)
	back_button.pressed.connect(go_to_market)
	check_button.pressed.connect(_on_check_pressed)
	next_level_button.pressed.connect(_on_next_level_pressed)
	apple_bowl_view.gui_input.connect(_on_tray_apple_input)

	balance_visual.set_tilt(0.3) # tehtnica ima najprej nagib na desni strani zaradi uteži

	# oznaki za mase poravnam na sredino skledic tehtnice
	for label in [left_mass_label, right_mass_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = LABEL_SIZE
		label.size = LABEL_SIZE

	# položaj besedila z navodili
	info_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	info_label.position = Vector2(INFO_MARGIN, INFO_TOP)
	info_label.custom_minimum_size = Vector2(GAME_SIZE.x - INFO_MARGIN * 2.0, 0)
	info_label.size = Vector2(GAME_SIZE.x - INFO_MARGIN * 2.0, 0)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_label.add_theme_font_size_override("font_size", INFO_FONT_SIZE)
	
	update_mass_label_positions()

func start_game() -> void:
	instructions_panel.visible = false
	
	for node in game_nodes:
		node.visible = true

	level_index = 0
	load_level()

func load_level() -> void:
	var level: Dictionary = LEVELS[level_index]
	target_mass = level["mass"]

	for apple in apples:
		apple.queue_free()
		
	apples.clear()

	locked = false
	next_level_button.visible = false
	info_label.text = level["story"] % target_mass

	# v zadnji stopnji gumbek izpiše "Končaj"
	if level_index == LEVELS.size() - 1:
		next_level_button.text = "Končaj"
	else:
		next_level_button.text = "Naslednja stopnja"

	update_balance()

func _on_next_level_pressed() -> void:
	if level_index < LEVELS.size() - 1:
		level_index += 1
		load_level()
	else:
		MarketGameProgress.easy_completed = true
		level_completed.emit()
		go_to_market()

# klik event za miško da se doda jabolka na tehtnico
func _on_tray_apple_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		add_apple()

func add_apple() -> void:
	if locked or apples.size() >= MAX_APPLES:
		return
		
	var apple = APPLE_SCENE.instantiate()
	apple.scale = Vector2.ONE
	apple.custom_minimum_size = Vector2(APPLE_SIZE, APPLE_SIZE)
	apple.size = Vector2(APPLE_SIZE, APPLE_SIZE)
	apple.show_behind_parent = true
	apple.gui_input.connect(_on_placed_apple_input.bind(apple))
	
	balance_visual.add_child(apple)
	apples.append(apple)
	update_balance()

# za odstranitev jabolke ob kliku nanjo
func _on_placed_apple_input(event: InputEvent, apple: Control) -> void:
	if locked:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		apples.erase(apple)
		apple.queue_free()
		update_balance()

# preverim če sta masi na obeh straneh enaki
func _on_check_pressed() -> void:
	locked = true
	check_button.visible = false

	var left_mass: int = apples.size() * APPLE_MASS

	if left_mass == target_mass:
		if level_index == LEVELS.size() - 1:
			info_label.text = "Čestitam! Vsa naročila so uspešno pripravljena! Klikni na gumb \"Končaj\" in se pomeri v težjih izzivih."
		else:
			info_label.text = "Čestitam! Naročilo je pravilno pripravljeno in tehtnica je v ravnovesju. Klikni na gumb \"Naslednja stopnja\" za nadaljevanje."
		next_level_button.visible = true
		return

	if left_mass < target_mass:
		info_label.text = "Ojoj, premalo jabolk! Utež je še vedno pretežka. Poskusi znova!"
	else:
		info_label.text = "Uf, preveč jabolk! Sedaj so težja od uteži. Poskusi znova!"

	await get_tree().create_timer(RESET_DELAY).timeout

	# po napačnem odgovoru znova naložim isto stopnjo (če igralec medtem ni zapustil scene)
	if is_inside_tree():
		load_level()

# posodobim oznake mase, vidnost gumba za preverjanje pa nagib tehtnice
func update_balance() -> void:
	var left_mass: int = apples.size() * APPLE_MASS

	left_mass_label.text = "%d g" % left_mass
	right_mass_label.text = "%d g" % target_mass

	check_button.visible = apples.size() > 0 and not locked
	
	# izračunam ciljni nagib glede na razliko med masama (clampf mi omeji nagib med -0.3 pa 0.3)
	var target := clampf((target_mass - left_mass) * 0.0005, -0.3, 0.3)
	
	# s tem se izvede animacija nagiba
	balance_visual.animate_tilt(target)

# s tem posodobim pozicijo oznak mase glede na trenutni položaj tehtnice
func update_mass_label_positions() -> void:
	var left_center: Vector2 = balance_visual.global_position + balance_visual.get_left_pan_pos() + Vector2(0, LABEL_BOWL_OFFSET)
	var right_center: Vector2 = balance_visual.global_position + balance_visual.get_right_pan_pos() + Vector2(0, LABEL_BOWL_OFFSET)

	left_mass_label.global_position = left_center - LABEL_SIZE / 2.0
	right_mass_label.global_position = right_center - LABEL_SIZE / 2.0
	
func go_to_market() -> void:
	get_tree().change_scene_to_file(MARKET_SCENE)

func _process(_delta: float) -> void:
	update_mass_label_positions()

	var base: Vector2 = balance_visual.get_left_pan_pos()
	
	# za razporejanje jabolk na tehtnici, da bo lepše
	for i in apples.size():
		var slot: Vector2 = SLOTS[i]
		var spot := base + Vector2(
			slot.x * APPLE_SIZE * 0.85,
			slot.y * APPLE_SIZE * 0.75
		)
		apples[i].position = spot - Vector2(APPLE_SIZE / 2.0, APPLE_SIZE * 0.7) + APPLE_OFFSET
