extends Node2D

var particles: Array[Dictionary] = []
var lifetime: float = 0.55

func setup(direction: Vector2, heavy: bool) -> void:
	for i in range(18 if heavy else 10):
		var velocity := direction.rotated(randf_range(-1.5, 1.5)) * randf_range(20.0, 95.0)
		particles.append({"p": Vector2.ZERO, "v": velocity, "color": Color("b34855") if i % 3 else Color("f7d99a"), "size": 2 if i % 4 == 0 else 1})

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	for particle in particles:
		particle.p += particle.v * delta
		particle.v = particle.v.move_toward(Vector2.ZERO, delta * 135.0)
	modulate.a = minf(1.0, lifetime * 4.0)
	queue_redraw()

func _draw() -> void:
	for particle in particles:
		draw_rect(Rect2(particle.p.round(), Vector2.ONE * particle.size), particle.color)
