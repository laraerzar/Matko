@tool
extends Control

const FACE_COLOR := Color("fff8e7")
const RIM_COLOR := Color("2b3a67")
const HOUR_COLOR := Color("2b3a67")
const MINUTE_COLOR := Color("e4572e")

@export_range(0, 23) var hours: int = 3:
	set(value):
		hours = value
		queue_redraw()

@export_range(0, 59) var minutes: int = 20:
	set(value):
		minutes = value
		queue_redraw()

func set_time(h: int, m: int) -> void:
	hours = h
	minutes = m

func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 6.0

	draw_circle(c, r, FACE_COLOR)
	draw_arc(c, r, 0.0, TAU, 96, RIM_COLOR, 6.0, true)

	for i in 60:
		var dir := Vector2.from_angle(i * TAU / 60.0 - PI / 2.0)
		if i % 5 == 0:
			draw_line(c + dir * r * 0.86, c + dir * r * 0.95, RIM_COLOR, 3.0, true)
		else:
			draw_line(c + dir * r * 0.91, c + dir * r * 0.95, RIM_COLOR, 1.5, true)

	var font := ThemeDB.fallback_font
	var font_size := int(r * 0.2)
	for n in range(1, 13):
		var p := c + Vector2.from_angle(n * TAU / 12.0 - PI / 2.0) * r * 0.72
		draw_string(font, Vector2(p.x - 20.0, p.y + font_size * 0.35), str(n),
				HORIZONTAL_ALIGNMENT_CENTER, 40.0, font_size, RIM_COLOR)

	var m_angle := minutes * TAU / 60.0 - PI / 2.0
	var h_angle := ((hours % 12) + minutes / 60.0) * TAU / 12.0 - PI / 2.0
	draw_line(c, c + Vector2.from_angle(h_angle) * r * 0.45, HOUR_COLOR, 8.0, true)
	draw_line(c, c + Vector2.from_angle(m_angle) * r * 0.65, MINUTE_COLOR, 5.0, true)
	draw_circle(c, r * 0.06, RIM_COLOR)
