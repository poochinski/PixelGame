class_name MoneyPickup
extends Node2D

@export_range(1, 10) var amount: int = 1
@export var pickup_radius: float = 12.0
@export var settle_time: float = 0.45
var collector: CombatPlayer
var age: float = 0.0
var collected: bool = false

func _ready() -> void:
	add_to_group("money_pickups")
	z_index = 10

func _physics_process(delta: float) -> void:
	age += delta
	try_collect()
	queue_redraw()

func try_collect() -> bool:
	if collected or age < settle_time or not is_instance_valid(collector) or collector.health.dead:
		return false
	if global_position.distance_to(collector.global_position) > pickup_radius:
		return false
	var ray := PhysicsRayQueryParameters2D.create(global_position, collector.global_position, 1)
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		return false
	# Mark before emitting inventory signals, so overlapping checks cannot pay twice.
	collected = true
	collector.inventory.add_cash(amount)
	CombatFX.sound("cash")
	queue_free()
	return true

static func draw_bill(canvas: CanvasItem, at: Vector2) -> void:
	canvas.draw_rect(Rect2(at + Vector2(-6, -3), Vector2(12, 7)), Color("142f29"))
	canvas.draw_rect(Rect2(at + Vector2(-5, -2), Vector2(10, 5)), Color("8ec695"))
	canvas.draw_rect(Rect2(at + Vector2(-3, -1), Vector2(6, 3)), Color("3e795a"))
	canvas.draw_rect(Rect2(at + Vector2(-1, -1), Vector2(2, 3)), Color("dbe7af"))
	canvas.draw_line(at + Vector2(-4, 0), at + Vector2(-4, 1), Color("dbe7af"))
	canvas.draw_line(at + Vector2(4, 0), at + Vector2(4, 1), Color("dbe7af"))

func _draw() -> void:
	draw_set_transform(Vector2(0, 1), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 8, Color(0.05, 0.1, 0.06, 0.7))
	draw_arc(Vector2.ZERO, 9, 0, TAU, 16, Color(0.6, 0.86, 0.57, 0.55), 1)
	draw_set_transform(Vector2.ZERO)
	var bounce := sin(clampf(age / settle_time, 0, 1) * PI) * 10.0
	var at := Vector2(0, roundf(-5.0 - bounce - sin(age * 3.0)))
	draw_bill(self, at)
	if sin(age * 5.0) > 0.5:
		draw_line(at + Vector2(8, -5), at + Vector2(8, -1), Color("f4e6ae"))
		draw_line(at + Vector2(6, -3), at + Vector2(10, -3), Color("f4e6ae"))
	var text := "$%d" % amount
	var font := ThemeDB.fallback_font
	var x := -font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x * 0.5
	draw_string(font, Vector2(x + 1, at.y - 5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("10131c"))
	draw_string(font, Vector2(x, at.y - 6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("dbe7af"))
