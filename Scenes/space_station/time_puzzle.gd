extends Control
signal puzzle_completed(mistakes: int)

@onready var time_label: Label = $VBoxContainer/TimeLabel
@onready var prompt_label: Label = $VBoxContainer/PromptLabel
@onready var progress_label: Label = $VBoxContainer/ProgressLabel
@onready var options: HBoxContainer = $VBoxContainer/Options
@onready var levels: HBoxContainer = $VBoxContainer/Levels

# 0 = Lahko, 1 = Srednje, 2 = Težko, 3 = Potovanje
@export_enum("Lahko", "Srednje", "Težko", "Potovanje") var difficulty: int = 0
@export var questions_to_win: int = 5

var easy_minutes: Array[int] = [0, 15, 30, 45]
var correct_index: int = 0
var correct_count: int = 0
var mistakes: int = 0
var locked: bool = false
var round_id: int = 0

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

func update_progress() -> void:
	progress_label.text = "Pravilno: %d / %d" % [correct_count, questions_to_win]

func finish() -> void:
	locked = true
	prompt_label.text = "Odlično! Vse pravilno rešeno."
	print("Puzzle completed, mistakes: ", mistakes)
	puzzle_completed.emit(mistakes)

func new_question() -> void:
	locked = false
	var answers: Array[Vector2i]
	if difficulty == 3:
		answers = journey_question()
	else:
		answers = clock_question()
	# answers[0] is the correct time, the rest are wrong.
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
	var duration := randi_range(3, 36) * 5   # 15 to 180 minutes
	var arrival_total := dep.x * 60 + dep.y + duration
	time_label.text = "%02d:%02d" % [dep.x, dep.y]
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
