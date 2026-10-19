extends Control

@onready var time_label: Label = $VBoxContainer/TimeLabel
@onready var prompt_label: Label = $VBoxContainer/PromptLabel
@onready var options: HBoxContainer = $VBoxContainer/Options

# 0 = Lahko, 1 = Srednje, 2 = Težko
@export_enum("Lahko", "Srednje", "Težko") var difficulty: int = 0

var easy_minutes: Array[int] = [0, 15, 30, 45]
var correct_index: int = 0
var locked: bool = false

func _ready() -> void:
	for i in $VBoxContainer/Levels.get_child_count():
		var level_button: Button = $VBoxContainer/Levels.get_child(i)
		level_button.pressed.connect(set_difficulty.bind(i))
	for i in options.get_child_count():
		var button: Button = options.get_child(i)
		button.pressed.connect(_on_option_pressed.bind(i))
	new_question()

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

func set_difficulty(level: int) -> void:
	difficulty = level
	new_question()

func new_question() -> void:
	locked = false
	prompt_label.text = "Izberi pravo uro"
	var target := random_time()
	time_label.text = "%02d:%02d" % [target.x, target.y]
	correct_index = randi_range(0, options.get_child_count() - 1)

	var used: Array[Vector2i] = [target]
	for i in options.get_child_count():
		var t: Vector2i = target
		if i != correct_index:
			t = random_time()
			while t in used:
				t = random_time()
			used.append(t)
		var clock = options.get_child(i).get_child(0)
		clock.set_time(t.x, t.y)

func _on_option_pressed(index: int) -> void:
	if locked:
		return
	if index == correct_index:
		locked = true
		prompt_label.text = "Pravilno!"
		await get_tree().create_timer(1.2).timeout
		new_question()
	else:
		prompt_label.text = "Poskusi znova"
