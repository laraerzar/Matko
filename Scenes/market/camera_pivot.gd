extends Node3D

@export var mouse_sensitivity: float = 0.003

var rotating := false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			rotating = event.pressed

			if rotating:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	elif event is InputEventMouseMotion and rotating:
		rotate_y(-event.relative.x * mouse_sensitivity)
