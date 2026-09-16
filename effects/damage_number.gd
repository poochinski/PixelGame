extends Node2D

var amount: int = 0
var emphasized: bool = false
var player_damage: bool = false
var age: float = 0.0
var drift: float = 0.0

func _ready() -> void:
	drift = randf_range(-9.0, 9.0)
	z_index = 30

func _process(delta: float) -> void:
	age += delta
	position += Vector2(drift, -24.0 + age * 17.0) * delta
	modulate.a = clampf((0.8 - age) * 4.0, 0.0, 1.0)
	if age > 0.8:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var text := str(amount) + ("!" if emphasized else "")
	var color := Color("ef8d8d") if player_damage else Color("ffe0a1") if emphasized else Color("eee4cf")
	draw_string(ThemeDB.fallback_font, Vector2(-5, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10 if emphasized else 8, Color("10121c"))
	draw_string(ThemeDB.fallback_font, Vector2(-6, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10 if emphasized else 8, color)
