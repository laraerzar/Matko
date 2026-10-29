extends Control

const RADIUS := 120.0
const FOOD_CENTER := Vector2(200, 190)
const PLATE_CENTER := Vector2(620, 190)
const PLATE_RADIUS := 150.0

var parts := 2
var on_plate: Array[bool] = []
var dragging := -1
var grab_point := Vector2.ZERO
var drag_offset := Vector2.ZERO

func setup(new_parts: int) -> void:
	parts = new_parts
	on_plate.clear()
	on_plate.resize(parts)
	on_plate.fill(false)
	dragging = -1
	drag_offset = Vector2.ZERO
	queue_redraw()

func plate_count() -> int:
	return on_plate.count(true)

func _slice_origin(i: int) -> Vector2:
	var base := PLATE_CENTER if on_plate[i] else FOOD_CENTER
	if i == dragging:
		base += drag_offset
	return base

func _world_points(i: int) -> PackedVector2Array:
	var origin := _slice_origin(i)
	var a0 := -PI / 2.0 + i * TAU / parts
	var a1 := a0 + TAU / parts
	var pts := PackedVector2Array()
	pts.append(origin)
	for s in 17:
		var a := lerpf(a0, a1, s / 16.0)
		pts.append(origin + Vector2(cos(a), sin(a)) * RADIUS)
	return pts

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var plate_fill := Color(0.95, 0.95, 1.0)
	var plate_border := Color(0.25, 0.35, 0.6)
	var text_color := Color(0.3, 0.2, 0.1)
	draw_circle(PLATE_CENTER, PLATE_RADIUS, plate_fill)
	draw_arc(PLATE_CENTER, PLATE_RADIUS, 0.0, TAU, 64, plate_border, 6.0)
	draw_string(font, PLATE_CENTER + Vector2(-80, PLATE_RADIUS + 30), "Krožnik", HORIZONTAL_ALIGNMENT_CENTER, 160, 24, text_color)
	draw_string(font, Vector2(FOOD_CENTER.x - 130, 24), "Povleci kose na krožnik", HORIZONTAL_ALIGNMENT_CENTER, 260, 20, text_color)
	for i in parts:
		if i != dragging:
			_draw_slice(i)
	if dragging >= 0:
		_draw_slice(dragging)
		
func _draw_slice(i: int) -> void:
	var origin := _slice_origin(i)
	var pts := _world_points(i)
	var a0 := -PI / 2.0 + i * TAU / parts
	var a1 := a0 + TAU / parts
	var mid := (a0 + a1) / 2.0
	var cheese := Color(0.98, 0.8, 0.35)
	draw_colored_polygon(pts, cheese.lightened(0.25) if i == dragging else cheese)
	draw_arc(origin, RADIUS - 4.0, a0, a1, 16, Color(0.75, 0.45, 0.15), 8.0)
	var rings: Array = [0.4, 0.72] if parts <= 6 else [0.62]
	for f in rings:
		var rho: float = RADIUS * f
		var r: float = minf(14.0, rho * sin(PI / parts) * 0.6)
		var p := origin + Vector2(cos(mid), sin(mid)) * rho
		draw_circle(p, r, Color(0.8, 0.12, 0.1))
		draw_arc(p, r, 0.0, TAU, 16, Color(0.5, 0.05, 0.05), 2.0)
	pts.append(pts[0])
	draw_polyline(pts, Color(0.3, 0.2, 0.1), 3.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			for i in range(parts - 1, -1, -1):
				if Geometry2D.is_point_in_polygon(event.position, _world_points(i)):
					dragging = i
					grab_point = event.position
					drag_offset = Vector2.ZERO
					queue_redraw()
					break
		elif dragging >= 0:
			_drop()
	elif event is InputEventMouseMotion and dragging >= 0:
		drag_offset = event.position - grab_point
		queue_redraw()

func _drop() -> void:
	var pts := _world_points(dragging)
	var c := Vector2.ZERO
	for p in pts:
		c += p
	c /= pts.size()
	on_plate[dragging] = c.distance_to(PLATE_CENTER) < PLATE_RADIUS
	dragging = -1
	drag_offset = Vector2.ZERO
	queue_redraw()
