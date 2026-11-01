extends CanvasLayer

signal finished(success: bool)

const ORDER_COUNT := 5
const PASS_SCORE := 3
const MODE_NAMES := ["Lahko", "Srednje", "Težko"]
const EASY_DENOMINATORS := [2, 3, 4, 6, 8]
const MEDIUM_TOTALS := [6, 8, 12]
const HARD_PAIRS := [[2, 3], [3, 4], [2, 6], [3, 6], [4, 6], [2, 5]]

var mode := 0
var orders: Array = []
var current := 0
var score := 0
var parts := 2

@onready var menu_box: VBoxContainer = $MenuBox
@onready var game_box: VBoxContainer = $VBoxContainer
@onready var result_box: VBoxContainer = $ResultBox
@onready var result_label: Label = $ResultBox/ResultLabel
@onready var question_label: Label = $VBoxContainer/QuestionLabel
@onready var shape = $VBoxContainer/FractionShape
@onready var parts_row: HBoxContainer = $VBoxContainer/PartsRow
@onready var feedback_label: Label = $VBoxContainer/FeedbackLabel
@onready var submit_button: Button = $VBoxContainer/SubmitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	$MenuBox/EasyButton.pressed.connect(func(): _begin(0))
	$MenuBox/MediumButton.pressed.connect(func(): _begin(1))
	$MenuBox/HardButton.pressed.connect(func(): _begin(2))
	$VBoxContainer/PartsRow/MinusButton.pressed.connect(func(): _set_parts(parts - 1))
	$VBoxContainer/PartsRow/PlusButton.pressed.connect(func(): _set_parts(parts + 1))
	$VBoxContainer/PartsRow/MinusButton.pressed.connect(_on_minus)
	$VBoxContainer/PartsRow/PlusButton.pressed.connect(_on_plus)
	$ResultBox/RetryButton.pressed.connect(_on_main_button)
	$ResultBox/BackToMenuButton.pressed.connect(_show_menu)
	$ResultBox/ExitButton.pressed.connect(_exit)
	submit_button.pressed.connect(_on_submit)

func start() -> void:
	visible = true
	_begin(0)

func _show_menu() -> void:
	menu_box.visible = true
	game_box.visible = false
	result_box.visible = false

func _exit() -> void:
	visible = false
	finished.emit(false)

func _begin(chosen_mode: int) -> void:
	mode = chosen_mode
	current = 0
	score = 0
	menu_box.visible = false
	result_box.visible = false
	game_box.visible = true
	_make_orders()
	_show_order()

func _show_results() -> void:
	game_box.visible = false
	result_box.visible = true
	$ResultBox/BackToMenuButton.visible = false
	var text := ""
	if score < PASS_SCORE:
		text = "Ni uspelo!\nPravilnih odgovorov: %d/%d" % [score, orders.size()]
		$ResultBox/RetryButton.text = "Poskusi znova"
	elif mode < 2:
		text = "Pravilnih odgovorov: %d/%d" % [score, orders.size()]
		$ResultBox/RetryButton.text = "Naprej"
	else:
		text = "Zmagal si!\nPravilnih odgovorov: %d/%d" % [score, orders.size()]
		$ResultBox/RetryButton.text = "Končaj"
	result_label.text = text

func _on_main_button() -> void:
	if score < PASS_SCORE:
		_begin(mode)
	elif mode < 2:
		_begin(mode + 1)
	else:
		visible = false
		finished.emit(true)

func _make_orders() -> void:
	orders.clear()
	for i in ORDER_COUNT:
		if mode == 0:
			orders.append(_easy_order())
		elif mode == 1:
			orders.append(_medium_order())
		else:
			orders.append(_hard_order())

func _easy_order() -> Dictionary:
	var den: int = EASY_DENOMINATORS.pick_random()
	var num := randi_range(1, den - 1)
	return {
		"den": den,
		"num": num,
		"text": "Stranka želi %d/%d pice. Razreži pico in povleci pravo število kosov na krožnik." % [num, den]
	}

@warning_ignore("integer_division")
func _medium_order() -> Dictionary:
	var total: int = MEDIUM_TOTALS.pick_random()
	var dens: Array = []
	for d in range(2, total):
		if total % d == 0:
			dens.append(d)
	var den: int = dens.pick_random()
	var num := randi_range(1, den - 1)
	var need: int = num * (total / den)
	return {
		"total": total,
		"need": need,
		"text": "Pica je že razrezana na %d kosov. Stranka želi %d/%d pice. Povleci pravo število kosov na krožnik." % [total, num, den]
	}

func _hard_order() -> Dictionary:
	var d1 := 2
	var d2 := 3
	var a := 1
	var b := 1
	var ok := false
	while not ok:
		var pair: Array = HARD_PAIRS.pick_random()
		d1 = pair[0]
		d2 = pair[1]
		a = randi_range(1, d1 - 1)
		b = randi_range(1, d2 - 1)
		ok = float(a) / d1 + float(b) / d2 < 1.0
	return {
		"d1": d1,
		"d2": d2,
		"a": a,
		"b": b,
		"text": "Stranka želi %d/%d + %d/%d pice. Razreži pico tako, da ustreza obema ulomkoma, nato povleci skupno število kosov na krožnik." % [a, d1, b, d2]
	}

func _show_order() -> void:
	var q: Dictionary = orders[current]
	question_label.text = "%s - Naročilo %d/%d: %s" % [MODE_NAMES[mode], current + 1, orders.size(), q.text]
	feedback_label.text = ""
	submit_button.disabled = false
	parts_row.visible = mode != 1
	if mode == 1:
		parts = q.total
		shape.setup(parts)
	else:
		_set_parts(2)

func _set_parts(n: int) -> void:
	parts = clampi(n, 2, 12)
	shape.setup(parts)

@warning_ignore("integer_division")
func _is_correct(q: Dictionary) -> bool:
	if mode == 0:
		return shape.plate_count() * q.den == q.num * parts
	if mode == 1:
		return shape.plate_count() == q.need
	if parts % q.d1 != 0 or parts % q.d2 != 0:
		return false
	var need: int = q.a * (parts / q.d1) + q.b * (parts / q.d2)
	return shape.plate_count() == need

func _hint(q: Dictionary) -> String:
	if mode == 0:
		if (q.num * parts) % q.den != 0:
			return "Ni čisto prav. Pica je razrezana na kose, ki ne ustrezajo temu ulomku."
		return "Ni čisto prav. Preštej kose na krožniku."
	if mode == 1:
		return "Ni čisto prav. Koliko kosov ustreza temu ulomku?"
	if parts % q.d1 != 0 or parts % q.d2 != 0:
		return "Ni čisto prav. Razreži pico na dele, ki ustrezajo obema ulomkoma."
	return "Ni čisto prav. Seštej ulomka in preštej kose."

func _on_submit() -> void:
	var q: Dictionary = orders[current]
	submit_button.disabled = true
	if _is_correct(q):
		score += 1
		feedback_label.text = "Pravilno!"
	else:
		feedback_label.text = _hint(q)
	await get_tree().create_timer(1.2).timeout
	if not visible:
		return
	current += 1
	if current >= orders.size():
		_show_results()
	else:
		_show_order()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		visible = false
		finished.emit(false)
		
func _on_minus() -> void:
	$ClickSound.play()
	_set_parts(parts - 1)

func _on_plus() -> void:
	$ClickSound.play()
	_set_parts(parts + 1)
