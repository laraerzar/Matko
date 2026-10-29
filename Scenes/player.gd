extends CharacterBody3D

@export var speed: float = 5.0
@export var turn_speed: float = 12.0
@export var gravity: float = 20.0

@onready var model: Node3D = $Matko
@onready var anim: AnimationPlayer = $Matko/AnimationPlayer

var idle_anim: String = ""
var run_anim: String = ""

func _ready() -> void:
	idle_anim = _find_anim("idle")
	run_anim = _find_anim("run")
	print("Animations: ", anim.get_animation_list(), " | idle=", idle_anim, " | run=", run_anim)
	for anim_name in [idle_anim, run_anim]:
		if anim_name != "":
			anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	_play(idle_anim)

func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		input.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		input.x += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		input.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		input.y += 1.0
	input = input.normalized()

	var direction := Vector3(input.x, 0.0, input.y)

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	move_and_slide()

	if direction != Vector3.ZERO:
		var target_angle := atan2(direction.x, direction.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_angle, turn_speed * delta)
		_play(run_anim)
	else:
		_play(idle_anim)

func _play(anim_name: String) -> void:
	if anim_name != "" and anim.current_animation != anim_name:
		anim.play(anim_name, 0.15)

func _find_anim(keyword: String) -> String:
	for anim_name in anim.get_animation_list():
		if String(anim_name).to_lower().ends_with("|" + keyword):
			return anim_name
	return ""
	
func set_frozen(frozen: bool) -> void:
	set_physics_process(not frozen)
	if frozen:
		velocity = Vector3.ZERO
		_play(idle_anim)
