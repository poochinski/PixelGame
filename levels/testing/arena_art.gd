extends Node2D

var obstacles: Array[Rect2] = []
var font: Font

func _ready() -> void:
	font = ThemeDB.fallback_font
	queue_redraw()

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1989
	# Wet asphalt, patched concrete, broken seams and aggregate.
	draw_rect(Rect2(0, 0, 480, 320), Color("303745"))
	for y in range(128, 304, 16):
		for x in range(16, 464, 16):
			draw_rect(Rect2(x, y, 16, 16), Color("343b48") if rng.randf() < 0.3 else Color("303744"))
	for i in range(2800):
		var point := Vector2(rng.randi_range(16, 464), rng.randi_range(125, 302))
		draw_rect(Rect2(point, Vector2(1, 1)), Color("46505b") if i % 3 else Color("252b38"))
	for y in [148, 214, 280]:
		draw_line(Vector2(16, y), Vector2(464, y + 2), Color("202734"))
		draw_line(Vector2(16, y + 1), Vector2(464, y + 3), Color("3b414d"))
	for i in range(26):
		var point := Vector2(rng.randi_range(26, 440), rng.randi_range(139, 292))
		var vertices := PackedVector2Array([point, point + Vector2(7, -2), point + Vector2(12, 1), point + Vector2(19, 0)])
		draw_polyline(vertices, Color("1e2532"))
	# Puddles: broken horizontal reflections, not a uniform blue floor.
	for puddle in [Rect2(160, 134, 70, 16), Rect2(272, 206, 49, 15), Rect2(54, 236, 55, 13), Rect2(358, 151, 74, 19)]:
		paint_puddle(puddle, Color("222f41"))
		for i in range(16):
			var x := rng.randf_range(puddle.position.x + 5, puddle.end.x - 10)
			var y := rng.randf_range(puddle.position.y + 3, puddle.end.y - 3)
			var reflected := Color("846f71") if puddle.position.x < 240 else Color("647d89")
			draw_line(Vector2(x, y).round(), Vector2(x + rng.randi_range(3, 13), y).round(), Color(reflected, rng.randf_range(0.15, 0.45)))
	# Faded bay markings with chips and an oil-stained central work area.
	for x in [158, 310]:
		draw_rect(Rect2(x, 162, 2, 105), Color("85826b"))
	for x in range(160, 310, 18):
		draw_rect(Rect2(x, 265, 10, 2), Color("85826b"))
	for i in range(85):
		var point := Vector2(rng.randi_range(182, 290), rng.randi_range(185, 247))
		draw_rect(Rect2(point, Vector2(rng.randi_range(1, 4), 1)), Color("292f3a"))
	draw_string(font, Vector2(229, 252), "04", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("66675e"))
	# North building facade comes down into the playable view.
	draw_rect(Rect2(0, 0, 480, 124), Color("2b2935"))
	for y in range(0, 124, 6):
		for x in range(-12, 480, 14):
			var offset := 7 if y % 12 else 0
			var brick_color := Color("65545b") if rng.randf() > 0.3 else Color("554650")
			draw_rect(Rect2(x + offset, y, 13, 5), brick_color)
			draw_line(Vector2(x + offset, y), Vector2(x + offset + 12, y), Color("786168"))
	draw_rect(Rect2(16, 122, 448, 5), Color("7a7474"))
	draw_rect(Rect2(16, 127, 448, 8), Color(0.04, 0.05, 0.09, 0.6))
	# Corrugated shutters with recessed frames and scraped paint.
	for x in [40, 319]:
		draw_rect(Rect2(x - 3, 53, 100, 71), Color("242833"))
		draw_rect(Rect2(x, 56, 94, 65), Color("515961"))
		for y in range(57, 120, 4):
			draw_line(Vector2(x, y), Vector2(x + 93, y), Color("7b7e7d"))
			draw_line(Vector2(x, y + 1), Vector2(x + 93, y + 1), Color("363f4b"))
		draw_rect(Rect2(x + 42, 110, 13, 3), Color("242a35"))
		draw_rect(Rect2(x + 44, 110, 9, 1), Color("9c9b8b"))
		draw_string(font, Vector2(x + 8, 97), "KEEP CLEAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("b3a69b"))
	# Original service-yard sign, wiring and dirty amber windows.
	draw_rect(Rect2(183, 96, 113, 25), Color("252231"))
	draw_rect(Rect2(186, 99, 107, 19), Color("4e3b4b"), false)
	draw_string(font, Vector2(193, 111), "REQUIEM AUTO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e7a4a0"))
	draw_line(Vector2(193, 115), Vector2(286, 115), Color("dc8998"))
	draw_polyline(PackedVector2Array([Vector2(185, 99), Vector2(173, 98), Vector2(172, 72), Vector2(151, 68)]), Color("191f2c"), 2)
	for x in [150, 270]:
		draw_rect(Rect2(x, 59, 29, 28), Color("242732"))
		draw_rect(Rect2(x + 3, 62, 23, 21), Color("a28b69"))
		draw_rect(Rect2(x + 3, 65, 23, 3), Color("bba67e"))
		draw_line(Vector2(x + 14, 61), Vector2(x + 14, 84), Color("3d3b42"), 2)
		draw_line(Vector2(x + 2, 73), Vector2(x + 26, 73), Color("3d3b42"), 2)
	# Utility boxes, pipes and wall stains.
	draw_rect(Rect2(141, 99, 23, 22), Color("2d3840"))
	draw_rect(Rect2(143, 100, 19, 18), Color("66716e"))
	draw_rect(Rect2(147, 104, 6, 8), Color("343e47"))
	draw_rect(Rect2(156, 104, 2, 2), Color("caa27d"))
	for x in [24, 443]:
		draw_line(Vector2(x, 10), Vector2(x, 121), Color("282a36"), 5)
		draw_line(Vector2(x, 10), Vector2(x, 121), Color("797373"), 2)
		for y in [65, 101, 116]:
			draw_rect(Rect2(x - 3, y, 6, 2), Color("9b8880"))
	for x in [164, 338]:
		draw_rect(Rect2(x - 9, 119, 18, 3), Color("292a35"))
		draw_rect(Rect2(x - 7, 120, 14, 1), Color("ffe0ae"))
	# Side brick walls and concrete curb.
	for x in [0, 464]:
		draw_rect(Rect2(x, 124, 16, 196), Color("4a4652"))
		for y in range(124, 320, 8):
			draw_rect(Rect2(x + 1, y, 14, 7), Color("63515b"))
	draw_rect(Rect2(16, 302, 448, 3), Color("7b7271"))
	draw_rect(Rect2(16, 305, 448, 15), Color("353442"))
	# Dumpster volumes with lids, hinges, scratches, wheels and contact shadows.
	for obstacle in obstacles:
		draw_rect(Rect2(obstacle.position + Vector2(5, 5), obstacle.size + Vector2(2, 3)), Color("192330"))
		draw_rect(obstacle, Color("42554e"))
		draw_rect(Rect2(obstacle.position - Vector2(1, 3), Vector2(obstacle.size.x + 2, 7)), Color("768576"))
		draw_rect(Rect2(obstacle.position, Vector2(obstacle.size.x, 2)), Color("a0a394"))
		draw_rect(obstacle.grow(-3), Color("253d39"), false)
		for x in range(int(obstacle.position.x) + 6, int(obstacle.end.x) - 3, 9):
			draw_line(Vector2(x, obstacle.position.y + 7), Vector2(x, obstacle.end.y - 4), Color("75806a"))
		draw_rect(Rect2(obstacle.position + Vector2(16, 8), Vector2(16, 8)), Color("beb499"))
		draw_string(font, obstacle.position + Vector2(18, 14), "04", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("514b48"))
		for x in [obstacle.position.x + 5, obstacle.end.x - 8]:
			draw_rect(Rect2(x, obstacle.end.y - 2, 4, 4), Color("1b2430"))
	# Litter stays out of the central silhouettes.
	for center in [Vector2(76, 177), Vector2(402, 243), Vector2(125, 271)]:
		for i in range(8):
			var at: Vector2 = center + Vector2(rng.randi_range(-10, 10), rng.randi_range(-6, 6))
			draw_rect(Rect2(at, Vector2(rng.randi_range(2, 5), 2)), Color("9a9b87") if i % 2 else Color("716b68"))
	for x in range(328, 355, 3):
		draw_line(Vector2(x, 269), Vector2(x, 276), Color("151f2e"))
	draw_rect(Rect2(326, 268, 30, 10), Color("6a7276"), false)

func paint_puddle(rect: Rect2, color: Color) -> void:
	draw_set_transform(rect.get_center(), 0.0, rect.size * 0.5)
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO)

