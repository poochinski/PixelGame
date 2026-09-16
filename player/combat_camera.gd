extends Camera2D

@export var follow_speed: float = 7.0
@export var look_ahead: float = 10.0
@export var shake_scale: float = 1.0
@export var bounds := Rect2(160, 151, 160, 56)
@export var framing_offset := Vector2(0, -23)
var target: CombatPlayer
var trauma: float = 0.0

func _ready() -> void:
	CombatFX.camera = self
	position_smoothing_enabled = false

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var ahead := (target.get_global_mouse_position() - target.global_position).limit_length(100.0) / 100.0 * look_ahead
	global_position = global_position.lerp(target.global_position + ahead + framing_offset, 1.0 - exp(-follow_speed * delta))
	global_position.x = clampf(global_position.x, bounds.position.x, bounds.end.x)
	global_position.y = clampf(global_position.y, bounds.position.y, bounds.end.y)
	trauma = maxf(0.0, trauma - delta * 10.0)
	offset = Vector2(randf_range(-trauma, trauma), randf_range(-trauma, trauma)) * shake_scale
