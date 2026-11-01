@tool
extends Control

var tilt_angle: float = 0.0 # kot pod katerim je tehtnica nagnjena
var tilt_tween: Tween # za gladko animacijo

const GOLD := Color("#D99A25")
const ORANGE := Color("#B8690F")
const GRAY := Color("3c3c3cff")

const BEAM_HALF := 250.0 # polovica dolžine palice od središča do vsakega konca
const PAN_DROP := 230.0 # navpična razdalja od konca palice do posode tehtnice

# pridobim sredino tehtnice
func _center() -> Vector2:
	return Vector2(size.x / 2.0, size.y * 0.25)

# položaj leve in desne posode tehtnice
func get_left_pan_pos() -> Vector2:
	return _center() + Vector2(-BEAM_HALF, 0).rotated(tilt_angle) + Vector2(0, PAN_DROP)

func get_right_pan_pos() -> Vector2:
	return _center() + Vector2(BEAM_HALF, 0).rotated(tilt_angle) + Vector2(0, PAN_DROP)

# za risanje tehtnice
func _draw() -> void:
	var center := _center()

	# steber
	draw_colored_polygon(PackedVector2Array([
		Vector2(center.x - 8, center.y),
		Vector2(center.x + 8, center.y),
		Vector2(center.x + 22, center.y + 330),
		Vector2(center.x - 22, center.y + 330),
	]), ORANGE)

	# podstavek
	draw_colored_polygon(PackedVector2Array([
		Vector2(center.x - 100, center.y + 330),
		Vector2(center.x + 100, center.y + 330),
		Vector2(center.x + 140, center.y + 400),
		Vector2(center.x - 140, center.y + 400),
	]), GOLD)

	# palica
	draw_set_transform(center, tilt_angle) # središče vrtenja
	draw_rect(Rect2(-270, -10, 540, 16), GOLD)
	draw_set_transform(Vector2.ZERO, 0.0)

	# položaja obeh koncev palice
	var left_pivot := center + Vector2(-BEAM_HALF, 0).rotated(tilt_angle)
	var right_pivot := center + Vector2(BEAM_HALF, 0).rotated(tilt_angle)

	draw_weight(get_right_pan_pos())
	draw_pan(left_pivot)
	draw_pan(right_pivot)

	# 3 pikice na palici za lepši efekt povezanosti elementov
	draw_circle(center, 10.0, ORANGE)
	draw_circle(left_pivot, 8.0, ORANGE)
	draw_circle(right_pivot, 8.0, ORANGE)

# izris posode tehtnice ter vrvic
func draw_pan(pivot: Vector2) -> void:
	var rim_y := pivot.y + PAN_DROP

	# vrvi
	draw_line(pivot, Vector2(pivot.x - 100, rim_y), GOLD, 3.0)
	draw_line(pivot, Vector2(pivot.x, rim_y), GOLD, 3.0)
	draw_line(pivot, Vector2(pivot.x + 100, rim_y), GOLD, 3.0)

	var points := PackedVector2Array() # seznam točk za obliko posode
	
	for i in range(21):
		var angle := PI * i / 20.0
		
		points.append(Vector2(
			pivot.x + cos(angle) * 115,
			rim_y + sin(angle) * 60)
		)
	draw_colored_polygon(points, ORANGE)

# izris uteži v desni posodi tehtnice
func draw_weight(pan_pos: Vector2) -> void:
	# izrišem na sredini posode, velikosti 70%
	draw_set_transform(pan_pos + Vector2(0, -100), 0.0, Vector2(0.7, 0.7))

	# zgorji del uteži
	draw_rect(Rect2(-35, 0, 70, 25), GRAY)
	draw_circle(Vector2(-35, 12.5), 12.5, GRAY)
	draw_circle(Vector2(35, 12.5), 12.5, GRAY)
	
	# srednji del uteži
	draw_rect(Rect2(-28, 20, 56, 30), GRAY)
	
	# spodnji del uteži
	draw_colored_polygon(PackedVector2Array([
		Vector2(-52, 44),
		Vector2(52, 44),
		Vector2(89, 199),
		Vector2(-89, 199),
	]), GRAY)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# nastavi nagib tehtnice glede na podani kot
func set_tilt(value: float) -> void:
	tilt_angle = clampf(value, -0.30, 0.30)
	queue_redraw()

# za gladko animacijo nagiba
func animate_tilt(target: float) -> void:
	if tilt_tween:
		tilt_tween.kill()
	
	tilt_tween = create_tween()
	tilt_tween.tween_method(set_tilt, tilt_angle, target, 0.6).set_trans(Tween.TRANS_SINE)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
