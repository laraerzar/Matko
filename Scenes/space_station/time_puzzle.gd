extends Control
signal puzzle_completed(mistakes: int)

@onready var time_label: Label = $VBoxContainer/TimeLabel
@onready var prompt_label: Label = $VBoxContainer/PromptLabel
@onready var progress_label: Label = $VBoxContainer/ProgressLabel
@onready var options: HBoxContainer = $VBoxContainer/Options
@onready var levels: HBoxContainer = $VBoxContainer/Levels
@onready var diff_label: Label = $VBoxContainer/DiffLabel

# 0 = Lahko, 1 = Srednje, 2 = Težko, 3 = Potovanje
@export_enum("Lahko", "Srednje", "Težko", "Potovanje", "Obratno") var difficulty: int = 0
@export var questions_to_win: int = 10

var easy_minutes: Array[int] = [0, 15, 30, 45]
var correct_index: int = 0
var correct_count: int = 0
var mistakes: int = 0
var locked: bool = false
var round_id: int = 0
var level_plan: Array[int] = []

const HOURS_NOM: Array[String] = ["", "ena", "dve", "tri", "štiri", "pet", "šest", "sedem", "osem", "devet", "deset", "enajst", "dvanajst"]
const HOURS_ACC: Array[String] = ["", "eno", "dve", "tri", "štiri", "pet", "šest", "sedem", "osem", "devet", "deset", "enajst", "dvanajst"]
const HOURS_GEN: Array[String] = ["", "enih", "dveh", "treh", "štirih", "petih", "šestih", "sedmih", "osmih", "devetih", "desetih", "enajstih", "dvanajstih"]


func _ready() -> void:
	for i in options.get_child_count():
		var button: Button = options.get_child(i)
		button.pressed.connect(_on_option_pressed.bind(i))
	for i in levels.get_child_count():
		var level_button: Button = levels.get_child(i)
		level_button.pressed.connect(set_difficulty.bind(i))
	start_round()


func start_round() -> void:
	round_id += 1
	correct_count = 0
	mistakes = 0
	update_progress()
	new_question()

func set_difficulty(level: int) -> void:
	difficulty = level
	start_round()
	
func set_plan(plan: Array) -> void:
	level_plan.assign(plan)
	questions_to_win = level_plan.size()
	levels.visible = false
	diff_label.visible = false
	start_round()

func update_progress() -> void:
	progress_label.text = "Pravilno: %d / %d" % [correct_count, questions_to_win]

func finish() -> void:
	locked = true
	prompt_label.text = "Odlično! Vse pravilno rešeno."
	print("Puzzle completed, mistakes: ", mistakes)
	puzzle_completed.emit(mistakes)

func new_question() -> void:
	locked = false
	if level_plan.size() > 0:
		difficulty = level_plan[mini(correct_count, level_plan.size() - 1)]
	var answers: Array[Vector2i]
	if difficulty == 3:
		answers = journey_question()
	elif difficulty == 4:
		answers = word_question()
	else:
		answers = clock_question()
	correct_index = randi_range(0, options.get_child_count() - 1)
	var wrong := 1
	for i in options.get_child_count():
		var t: Vector2i
		if i == correct_index:
			t = answers[0]
		else:
			t = answers[wrong]
			wrong += 1
		var clock = options.get_child(i).get_child(0)
		clock.set_time(t.x, t.y)

func random_minute() -> int:
	match difficulty:
		0:
			return easy_minutes.pick_random()
		1:
			return randi_range(0, 11) * 5
		4:
			return randi_range(0, 11) * 5
		_:
			return randi_range(0, 59)

func random_time() -> Vector2i:
	return Vector2i(randi_range(1, 12), random_minute())

func clock_question() -> Array[Vector2i]:
	var target := random_time()
	time_label.text = "%02d:%02d" % [target.x, target.y]
	prompt_label.text = "Izberi pravo uro"
	var result: Array[Vector2i] = [target]
	while result.size() < options.get_child_count():
		var t := random_time()
		if not (t in result):
			result.append(t)
	return result

func journey_question() -> Array[Vector2i]:
	var dep := Vector2i(randi_range(1, 12), randi_range(0, 11) * 5)
	var duration := randi_range(3, 36) * 5
	var arrival_total := dep.x * 60 + dep.y + duration
	time_label.text = "Potovanje" % [dep.x, dep.y]
	prompt_label.text = "Ladja odpotuje ob %02d:%02d in potuje %s. Kdaj prispe?" % [
			dep.x, dep.y, duration_text(duration)]
	var result: Array[Vector2i] = [minutes_to_time(arrival_total)]
	# Wrong answers are "close" to the right one, like real mistakes.
	var offsets: Array[int] = [-60, -30, -20, -15, -10, -5, 5, 10, 15, 20, 30, 60]
	offsets.shuffle()
	for i in options.get_child_count() - 1:
		result.append(minutes_to_time(arrival_total + offsets[i]))
	return result

func minutes_to_time(total: int) -> Vector2i:
	var h := floori(total / 60.0) % 12
	if h == 0:
		h = 12
	return Vector2i(h, total % 60)

func unit(n: int, one: String, two: String, few: String, many: String) -> String:
	match n:
		1:
			return one
		2:
			return two
		3, 4:
			return few
		_:
			return many

func duration_text(total_minutes: int) -> String:
	var h := floori(total_minutes / 60.0)
	var m := total_minutes % 60
	var m_text := "%d %s" % [m, unit(m, "minuto", "minuti", "minute", "minut")]
	if h == 0:
		return m_text
	var h_text := "%d %s" % [h, unit(h, "uro", "uri", "ure", "ur")]
	if m == 0:
		return h_text
	return h_text + " in " + m_text

func _on_option_pressed(index: int) -> void:
	if locked:
		return
	if index == correct_index:
		locked = true
		correct_count += 1
		update_progress()
		prompt_label.text = "Pravilno!"
		var my_round := round_id
		await get_tree().create_timer(1.2).timeout
		if my_round != round_id:
			return
		if correct_count >= questions_to_win:
			finish()
		else:
			new_question()
	else:
		mistakes += 1
		prompt_label.text = "Poskusi znova"
		
func time_in_words(h: int, m: int) -> String:
	var next := h % 12 + 1
	var text := ""
	match m:
		0:
			return "Ura je %s" % HOURS_NOM[h]
		5:
			text = "pet čez %s" % HOURS_ACC[h]
		10:
			text = "deset čez %s" % HOURS_ACC[h]
		15:
			text = "četrt čez %s" % HOURS_ACC[h]
		20:
			text = "dvajset čez %s" % HOURS_ACC[h]
		25:
			text = "pet do pol %s" % HOURS_GEN[next]
		30:
			text = "pol %s" % HOURS_GEN[next]
		35:
			text = "pet čez pol %s" % HOURS_GEN[next]
		40:
			text = "dvajset do %s" % HOURS_GEN[next]
		45:
			text = "četrt do %s" % HOURS_GEN[next]
		50:
			text = "deset do %s" % HOURS_GEN[next]
		55:
			text = "pet do %s" % HOURS_GEN[next]
	return text.substr(0, 1).to_upper() + text.substr(1)


func word_question() -> Array[Vector2i]:
	var target := random_time()
	time_label.text = time_in_words(target.x, target.y)
	time_label.add_theme_font_size_override("font_size", 48)
	prompt_label.text = "Katera ura to pokaže?"
	var result: Array[Vector2i] = [target]
	var next_hour := target.x % 12 + 1
	var prev_hour := (target.x + 10) % 12 + 1
	var tricky: Array[Vector2i] = [
		Vector2i(next_hour, target.y),
		Vector2i(prev_hour, target.y),
		Vector2i(target.x, (target.y + 30) % 60),
		Vector2i(target.x, (60 - target.y) % 60),
	]
	tricky.shuffle()
	for t: Vector2i in tricky:
		if result.size() < options.get_child_count() and not (t in result):
			result.append(t)
	while result.size() < options.get_child_count():
		var t := random_time()
		if not (t in result):
			result.append(t)
	return result
