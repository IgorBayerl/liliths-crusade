extends Camera2D

var LOOK_AHEAD_FACTOR = 0.08
const SHIFT_TRANS = Tween.TRANS_SINE
const SHIFT_EASE = Tween.EASE_OUT
const SHIFT_DURATION = 1.0

var facing

onready var prev_camera_pos = get_camera_position()
onready var tween = $Tween

func _unhandled_key_input(event):
	if event.is_action_pressed("test_key"):
		LOOK_AHEAD_FACTOR = 0.2
	if event.is_action_released("test_key"):
		LOOK_AHEAD_FACTOR = 0.08

func _process(_delta):
	_check_facing()
	prev_camera_pos = get_camera_position()

func _check_facing():
#	print(facing)
	var new_facing = sign(get_camera_position().x - prev_camera_pos.x)
#	print(new_facing)
	if new_facing != 0 && facing != new_facing:
		facing = new_facing
		_ajust_camera_pos()

func _ajust_camera_pos():
	var target_offset = get_viewport_rect().size.x * facing * LOOK_AHEAD_FACTOR
	tween.interpolate_property(self, "position:x", position.x, target_offset, SHIFT_DURATION, SHIFT_TRANS, SHIFT_EASE)
	tween.start()


func _on_Player_GroundedUpdated(is_grounded):
	drag_margin_v_enabled = !is_grounded
#	print("is_grounded: ", is_grounded)
