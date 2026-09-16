extends Node2D

var interior: String = ""
var font: Font

func _ready() -> void:
	font = ThemeDB.fallback_font
	z_index = -10

func text(at: Vector2, value: String, color: Color, size: int = 8) -> void:
	draw_string(font, at + Vector2(1, 1), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("17202b"))
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	if interior.is_empty():
		draw_town()
	else:
		draw_room()

func draw_town() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8719
	draw_rect(Rect2(Vector2.ZERO, TownLayout.SIZE), Color("343e4b"))
	# Sidewalk slabs surround the main east-west street.
	for y in range(16, 464, 16):
		for x in range(16, 752, 16):
			draw_rect(Rect2(x, y, 15, 15), Color("56606a") if rng.randf() < 0.3 else Color("4c5562"))
	draw_rect(Rect2(16, 248, 736, 104), Color("2b3545"))
	for i in range(2300):
		var p := Vector2(rng.randi_range(18, 750), rng.randi_range(250, 350))
		draw_rect(Rect2(p, Vector2(1, 1)), Color("414d5d") if i % 3 else Color("232b3a"))
	for y in [244, 350]:
		draw_rect(Rect2(16, y, 736, 3), Color("87908d"))
		draw_rect(Rect2(16, y + 3, 736, 3), Color("222e3d"))
	for x in range(30, 744, 38):
		draw_rect(Rect2(x, 297, 20, 2), Color("a49570"))
	for x in [264, 488]:
		for y in range(259, 344, 14):
			draw_rect(Rect2(x, y, 22, 7), Color("9ca193"))
	for building in TownLayout.BUILDINGS:
		draw_building(building)
	# Green strips, planters and benches give the south walk its own shape.
	draw_rect(Rect2(38, 378, 250, 70), Color("283f3c"))
	for i in range(180):
		var p := Vector2(rng.randi_range(40, 286), rng.randi_range(380, 446))
		draw_rect(Rect2(p, Vector2(2, 1)), Color("4a6860"))
	for index in range(TownLayout.PROPS.size()):
		var rect := TownLayout.PROPS[index]
		draw_rect(Rect2(rect.position + Vector2(3, 5), rect.size), Color("1b2b37"))
		if index < 2:
			draw_rect(rect, Color("755b48"))
			for y in range(int(rect.position.y), int(rect.end.y), 5):
				draw_rect(Rect2(rect.position.x, y, rect.size.x, 3), Color("b5966c"))
		elif index == 2:
			draw_rect(rect, Color("7a7b75"))
			draw_rect(rect.grow(-3), Color("3e6553"))
			for i in range(25):
				var p := rect.position + Vector2(rng.randi_range(4, 65), rng.randi_range(3, 17))
				draw_rect(Rect2(p, Vector2(4, 3)), Color("769371") if i % 4 else Color("c59a87"))
		else:
			draw_rect(rect, Color("42665d"))
			draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5)), Color("87a18d"))
			draw_rect(rect.grow(-4), Color("28483f"), false)
	for p in [Vector2(38, 240), Vector2(267, 240), Vector2(501, 240), Vector2(729, 240), Vector2(448, 380)]:
		draw_circle(p + Vector2(0, 7), 23, Color(0.9, 0.7, 0.4, 0.055))
		draw_circle(p + Vector2(0, 7), 15, Color(0.9, 0.7, 0.4, 0.045))
		draw_rect(Rect2(p + Vector2(-2, -28), Vector2(4, 29)), Color("23303d"))
		draw_rect(Rect2(p + Vector2(-5, -31), Vector2(10, 6)), Color("5f6b70"))
		draw_rect(Rect2(p + Vector2(-4, -30), Vector2(8, 3)), Color("f5d6a0"))
	text(Vector2(335, 330), "M E R C Y  R O W", Color("737d89"), 9)
	text(Vector2(67, 435), "SOUTH WALK", Color("97aca0"), 8)
	text(Vector2(578, 444), "SERVICE ALLEY", Color("909b9e"), 8)
	# Low boundary wall.
	for rect in [Rect2(0, 0, 768, 16), Rect2(0, 464, 768, 16), Rect2(0, 0, 16, 480), Rect2(752, 0, 16, 480)]:
		draw_rect(rect, Color("252e3b"))
		draw_rect(rect.grow(-3), Color("647078"), false)

func draw_building(building: Dictionary) -> void:
	var r: Rect2 = building.rect
	var tint: Color = building.color
	draw_rect(Rect2(r.position + Vector2(6, 8), r.size), Color(0.035, 0.05, 0.08, 0.65))
	draw_rect(r, Color("615863") if building.id == "bar" else Color("626c72"))
	for y in range(int(r.position.y), int(r.end.y), 7):
		for x in range(int(r.position.x), int(r.end.x) - 12, 16):
			draw_rect(Rect2(x + (4 if y % 2 else 0), y, 14, 5), Color(0.65, 0.65, 0.66, 0.15))
	var roof := Rect2(r.position - Vector2(3, 3), Vector2(r.size.x + 6, 68))
	draw_rect(roof, Color("303e4c"))
	for y in range(int(roof.position.y) + 3, int(roof.end.y) - 1, 6):
		draw_line(Vector2(roof.position.x + 3, y), Vector2(roof.end.x - 3, y), Color("596573"))
	draw_rect(Rect2(roof.position + Vector2(12, 12), Vector2(29, 20)), Color("212f3c"))
	draw_rect(Rect2(roof.position + Vector2(14, 13), Vector2(25, 17)), Color("85908d"))
	for i in range(4):
		draw_line(roof.position + Vector2(17, 16 + i * 3), roof.position + Vector2(36, 16 + i * 3), Color("47555d"))
	draw_rect(Rect2(r.position.x - 4, r.position.y + 65, r.size.x + 8, 6), tint.darkened(0.25))
	draw_rect(Rect2(r.position.x - 4, r.position.y + 65, r.size.x + 8, 2), tint)
	for dx in [16, 120]:
		var at := r.position + Vector2(dx, 85)
		draw_rect(Rect2(at, Vector2(40, 43)), Color("263444"))
		draw_rect(Rect2(at + Vector2(3, 3), Vector2(34, 37)), tint.darkened(0.35))
		draw_rect(Rect2(at + Vector2(5, 5), Vector2(12, 15)), tint.lightened(0.08))
		draw_line(at + Vector2(20, 3), at + Vector2(20, 40), Color("31404d"), 2)
		draw_line(at + Vector2(3, 22), at + Vector2(37, 22), Color("31404d"), 2)
		draw_rect(Rect2(at + Vector2(-2, 42), Vector2(44, 3)), Color("9b9b91"))
	var door := Vector2(r.get_center().x, r.end.y)
	draw_rect(Rect2(door + Vector2(-15, -37), Vector2(30, 38)), Color("23303b"))
	draw_rect(Rect2(door + Vector2(-12, -34), Vector2(24, 33)), tint.darkened(0.65))
	draw_rect(Rect2(door + Vector2(-9, -31), Vector2(18, 15)), tint.darkened(0.1))
	draw_rect(Rect2(door + Vector2(7, -14), Vector2(2, 4)), Color("e0cba1"))
	draw_rect(Rect2(door + Vector2(-17, 0), Vector2(34, 5)), Color("b1aca0"))
	draw_rect(Rect2(door + Vector2(-20, 5), Vector2(40, 3)), Color("7d8585"))
	var sign := Rect2(r.position + Vector2(19, 73), Vector2(138, 14))
	draw_rect(sign, Color("202c39"))
	draw_rect(sign.grow(-1), tint.darkened(0.1), false)
	var width := font.get_string_size(building.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	text(Vector2(r.get_center().x - width / 2, sign.position.y + 10), building.name, tint, 8)
	if building.id == "hospital":
		draw_rect(Rect2(r.position + Vector2(81, 26), Vector2(14, 5)), Color("db8c8a"))
		draw_rect(Rect2(r.position + Vector2(85, 22), Vector2(5, 14)), Color("db8c8a"))

func draw_room() -> void:
	var hospital := interior == "hospital"
	var bar := interior == "bar"
	var base := Color("66564d") if bar else Color("536e70") if hospital else Color("5c6259")
	draw_rect(Rect2(0, 0, 320, 224), Color("172630"))
	for y in range(48, 216, 12):
		for x in range(16, 304, 16):
			draw_rect(Rect2(x, y, 15, 11), base.lightened(0.045) if (x / 16 + y / 12) % 2 else base)
	draw_rect(Rect2(16, 24, 288, 39), base.darkened(0.32))
	for x in range(18, 302, 8):
		draw_line(Vector2(x, 26), Vector2(x, 60), base.lightened(0.1))
	draw_rect(Rect2(16, 60, 288, 4), Color("b5ac91"))
	draw_rect(Rect2(16, 64, 288, 5), Color(0.04, 0.07, 0.09, 0.35))
	var heading := "CORNER SUPPLY" if interior == "shop" else "MERCY HOSPITAL" if hospital else "THE LAST LIGHT"
	text(Vector2(112, 47), heading, Color("ead4ac"), 9)
	for rect in TownLayout.room_obstacles(interior):
		draw_rect(Rect2(rect.position + Vector2(2, 4), rect.size), Color("263239"))
		draw_rect(rect, Color("77644e") if not hospital else Color("c0cfcb"))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5)), Color("c5ae87") if not hospital else Color("e1e4d2"))
		if rect.position.x == 96:
			draw_rect(Rect2(140, 74, 40, 14), Color("334648"))
			text(Vector2(145, 84), "JOBS" if bar else "CARE" if hospital else "SHOP", Color("d6d8b5"), 8)
		elif interior == "shop":
			for y in range(int(rect.position.y) + 9, int(rect.end.y) - 4, 18):
				for x in range(int(rect.position.x) + 4, int(rect.end.x) - 4, 10):
					draw_rect(Rect2(x, y, 7, 9), Color("b3c8aa"))
					draw_rect(Rect2(x + 2, y + 2, 3, 4), Color("b96568"))
				draw_rect(Rect2(rect.position.x, y + 11, rect.size.x, 3), Color("c5ae87"))
		elif hospital:
			draw_rect(Rect2(rect.position + Vector2(4, 8), Vector2(32, 13)), Color("e5e4d4"))
			draw_rect(Rect2(rect.position + Vector2(4, 24), Vector2(32, 23)), Color("87b8b0"))
			draw_line(rect.position + Vector2(4, 29), rect.position + Vector2(35, 29), Color("c7d8c5"))
		else:
			draw_rect(Rect2(rect.get_center() - Vector2(3, 4), Vector2(5, 6)), Color("d7b486"))
			for dx in [-8, 37]:
				draw_rect(Rect2(rect.position + Vector2(dx, 4), Vector2(5, 16)), Color("a47b5c"))
	if bar:
		for x in range(42, 92, 9):
			draw_rect(Rect2(x, 42, 4, 13), Color("86a594"))
			draw_rect(Rect2(x + 1, 39, 2, 4), Color("c5b48d"))
		draw_rect(Rect2(241, 34, 38, 22), Color("a48866"))
		for x in [245, 261]:
			draw_rect(Rect2(x, 38, 12, 14), Color("dbceaa"))
	elif hospital:
		draw_rect(Rect2(46, 39, 20, 6), Color("d78985"))
		draw_rect(Rect2(53, 32, 6, 20), Color("d78985"))
	draw_rect(Rect2(16, 212, 288, 4), Color("a7a696"))
	draw_rect(Rect2(141, 212, 38, 4), Color("273b45"))
	draw_rect(Rect2(142, 188, 36, 20), Color("344e50"))
	text(Vector2(148, 202), "EXIT", Color("b9d4b9"), 8)
