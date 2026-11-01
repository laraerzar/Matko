extends Control

signal travel_requested(planet_id: String)

@onready var planets_box: HBoxContainer = $Center/VBox/Planets

func refresh() -> void:
	for child in planets_box.get_children():
		child.queue_free()
	for id in GameState.PLANET_ORDER:
		var data: Dictionary = GameState.PLANETS[id]
		var entry := VBoxContainer.new()
		entry.add_theme_constant_override("separation", 12)

		var pic := TextureRect.new()
		pic.texture = load(data["texture"])
		pic.custom_minimum_size = Vector2(180, 180)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		entry.add_child(pic)

		var name_label := Label.new()
		name_label.text = data["name"]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 24)
		entry.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = data["desc"]
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.add_theme_font_size_override("font_size", 16)
		entry.add_child(desc_label)

		var button := Button.new()
		button.add_theme_font_size_override("font_size", 22)
		if GameState.is_completed(id):
			button.text = "Opravljeno"
			button.disabled = true
			pic.modulate = Color(1, 1, 1, 0.5)
		elif GameState.is_next(id):
			button.text = "Odpotuj"
			button.pressed.connect(func(): travel_requested.emit(id))
		else:
			button.text = "Zaklenjeno"
			button.disabled = true
			pic.modulate = Color(0.25, 0.25, 0.35, 1)
		entry.add_child(button)

		planets_box.add_child(entry)
