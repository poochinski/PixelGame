extends Control

var arena: Node2D
var player: CombatPlayer
var font: Font
var debug_visible: bool = false
var cash_notice: String = ""
var cash_notice_left: float = 0.0
var title_text: String = "NEON REQUIEM"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font
	player.inventory.cash_added.connect(_cash_added)

func _process(delta: float) -> void:
	if not get_tree().paused:
		cash_notice_left = maxf(0, cash_notice_left - delta)
	queue_redraw()

func _cash_added(amount: int, _total: int) -> void:
	cash_notice = "+$%d COLLECTED" % amount
	cash_notice_left = 1.8

func label_at(at: Vector2, text: String, color: Color = Color("e0d9c8"), size: int = 8) -> void:
	draw_string(font, at + Vector2(0, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("10131c"))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	if not is_instance_valid(player):
		return
	draw_rect(Rect2(0, 0, 320, 30), Color(0.04, 0.055, 0.085, 0.94))
	draw_line(Vector2(0, 29), Vector2(320, 29), Color("4d414c"))
	label_at(Vector2(8, 10), title_text, Color("dfb699"))
	label_at(Vector2(217, 10), "CASH $%d" % player.inventory.cash, Color("b3db9f"))
	draw_rect(Rect2(8, 16, 79, 5), Color("49333f"))
	draw_rect(Rect2(8, 16, 79 * player.health.current / player.health.maximum, 5), Color("c86d71"))
	label_at(Vector2(92, 21), "%03d" % int(player.health.current), Color("e5c2b0"))
	var dodge_ready := player.cooldown_left <= 0.0
	label_at(Vector2(127, 21), "DODGE", Color("a4b6af"))
	draw_rect(Rect2(160, 17, 28, 3), Color("273d42"))
	draw_rect(Rect2(160, 17, 28 * (1.0 - player.cooldown_left / player.dodge_cooldown), 3), Color("90c9b6"))
	label_at(Vector2(199, 21), "BAT", Color("b99d7b"))
	for i in range(3):
		var on := player.weapon_controller.combo > i and (player.weapon_controller.busy or player.weapon_controller.combo_remaining > 0.0)
		draw_rect(Rect2(222 + i * 9, 16, 6, 5), Color("e4c084") if on else Color("3c4148"))
	label_at(Vector2(266, 21), "KOs %02d" % arena.kills)
	draw_footer()
	if arena.thug_wait > 0.0:
		label_at(Vector2(107, 145), "NEXT THUG IN %.1f" % arena.thug_wait, Color("dbbd88"))
	if cash_notice_left > 0.0:
		draw_rect(Rect2(103, 121, 114, 14), Color(0.04, 0.08, 0.065, 0.9))
		label_at(Vector2(111, 131), cash_notice, Color("c4e8a3"))
	if debug_visible:
		draw_rect(Rect2(6, 33, 125, 31), Color(0.02, 0.03, 0.05, 0.85))
		label_at(Vector2(10, 42), "FPS %d  POS %d,%d" % [Engine.get_frames_per_second(), player.position.x, player.position.y], Color("a4d4b7"), 7)
		label_at(Vector2(10, 51), "IFRAMES %.2f" % player.health.invulnerability, Color("a4d4b7"), 7)
		label_at(Vector2(10, 60), "PHASE %d / THUG %d" % [player.weapon_controller.phase, arena.thug.state if is_instance_valid(arena.thug) else -1], Color("a4d4b7"), 7)
	if player.health.dead:
		draw_rect(Rect2(0, 30, 320, 127), Color(0.06, 0.025, 0.045, 0.72))
		label_at(Vector2(96, 87), "SIGNAL LOST", Color("db9991"), 16)
		label_at(Vector2(95, 104), "BACK ON YOUR FEET IN %.1f" % maxf(arena.respawn_left, 0.0), Color("b7aea4"), 7)
	elif arena.inventory_open:
		draw_inventory()
	elif draw_custom_modal():
		pass
	elif get_tree().paused:
		draw_pause()
	else:
		var cursor := get_local_mouse_position().round()
		var color := Color("a8d9c5") if dodge_ready else Color("d7c7a6")
		draw_line(cursor + Vector2(-4, 0), cursor + Vector2(-2, 0), color)
		draw_line(cursor + Vector2(2, 0), cursor + Vector2(4, 0), color)
		draw_line(cursor + Vector2(0, -4), cursor + Vector2(0, -2), color)
		draw_line(cursor + Vector2(0, 2), cursor + Vector2(0, 4), color)

func draw_footer() -> void:
	draw_rect(Rect2(0, 157, 320, 23), Color(0.04, 0.055, 0.085, 0.94))
	label_at(Vector2(8, 167), "WASD MOVE   LMB COMBO   RMB HEAVY", Color("bcc4bd"))
	label_at(Vector2(249, 167), "I INVENTORY", Color("b3db9f"))
	label_at(Vector2(8, 176), "SPACE DODGE   R RESET   ESC PAUSE   F1 DEBUG", Color("7f929a"), 7)

func draw_custom_modal() -> bool:
	return false

func draw_pause() -> void:
	draw_rect(Rect2(0, 30, 320, 127), Color(0.03, 0.04, 0.06, 0.85))
	label_at(Vector2(126, 80), "PAUSED", Color("e1c7a0"), 14)
	label_at(Vector2(82, 99), "ESC RESUME   R RESTART ARENA", Color("bbc5bd"), 8)
	label_at(Vector2(85, 115), "BAIT THE SWING. PUNISH THE MISS.", Color("90a9a2"), 7)
	label_at(Vector2(126, 131), "I INVENTORY", Color("b3db9f"), 7)

func draw_inventory() -> void:
	draw_rect(Rect2(0, 30, 320, 127), Color(0.02, 0.03, 0.05, 0.88))
	draw_rect(Rect2(40, 39, 240, 111), Color("151e26"))
	draw_rect(Rect2(40, 39, 240, 111), Color("708978"), false, 1)
	draw_rect(Rect2(40, 39, 3, 111), Color("b3db9f"))
	label_at(Vector2(53, 56), "INVENTORY", Color("e5d6b8"), 12)
	label_at(Vector2(218, 55), "I / ESC CLOSE", Color("9aaea7"), 7)
	draw_line(Vector2(53, 63), Vector2(267, 63), Color("374b47"))
	draw_rect(Rect2(53, 73, 26, 26), Color("233831"))
	MoneyPickup.draw_bill(self, Vector2(66, 86))
	label_at(Vector2(89, 77), "POCKET CASH", Color("98afa1"), 7)
	label_at(Vector2(89, 96), "$%d" % player.inventory.cash, Color("c9e9a8"), 18)
	draw_line(Vector2(53, 105), Vector2(267, 105), Color("374b47"))
	label_at(Vector2(53, 117), "EQUIPPED", Color("98afa1"), 7)
	label_at(Vector2(114, 117), player.weapon_controller.weapon.display_name, Color("e5d6b8"), 8)
	label_at(Vector2(53, 139), "WALK OVER MONEY TO COLLECT IT", Color("98afa1"), 7)

func _input(event: InputEvent) -> void:
	if is_instance_valid(arena):
		arena.handle_input(event)
