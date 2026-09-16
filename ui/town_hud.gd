extends "res://ui/combat_hud.gd"

var notice: String = ""
var notice_left: float = 0.0

func notify(message: String) -> void:
	notice = message
	notice_left = 2.6

func _process(delta: float) -> void:
	super._process(delta)
	title_text = {"town": "MERCY ROW", "shop": "CORNER SUPPLY", "hospital": "MERCY HOSPITAL", "bar": "THE LAST LIGHT"}[arena.location]
	if not get_tree().paused:
		notice_left = maxf(0.0, notice_left - delta)

func _draw() -> void:
	super._draw()
	if not is_instance_valid(player) or player.health.dead or get_tree().paused:
		return
	if arena.location == "town" and arena.interaction_prompt.is_empty() and not debug_visible:
		draw_rect(Rect2(6, 33, 219, 12), Color(0.035, 0.05, 0.07, 0.82))
		label_at(Vector2(10, 42), arena.mission.summary(), Color("a6b9b0"), 7)
	if not arena.interaction_prompt.is_empty():
		var width := font.get_string_size(arena.interaction_prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		draw_rect(Rect2(156 - width / 2, 138, width + 8, 14), Color("1d3034"))
		label_at(Vector2(160 - width / 2, 148), arena.interaction_prompt, Color("d3e1b6"), 8)
	if notice_left > 0.0 and cash_notice_left <= 0.0:
		var width := font.get_string_size(notice, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		draw_rect(Rect2(156 - width / 2, 120, width + 8, 13), Color("1c2b32"))
		label_at(Vector2(160 - width / 2, 129), notice, Color("e0d2ae"), 7)

func draw_footer() -> void:
	draw_rect(Rect2(0, 157, 320, 23), Color(0.04, 0.055, 0.085, 0.96))
	label_at(Vector2(8, 167), "WASD MOVE   E INTERACT   I INVENTORY", Color("bcc4bd"), 8)
	label_at(Vector2(8, 176), "LMB / RMB ATTACK   SPACE DODGE   B BANDAGE   ESC PAUSE", Color("7f929a"), 7)

func draw_pause() -> void:
	draw_rect(Rect2(0, 30, 320, 127), Color(0.03, 0.04, 0.06, 0.9))
	label_at(Vector2(126, 79), "PAUSED", Color("e1c7a0"), 14)
	label_at(Vector2(96, 99), "ESC RESUME   I INVENTORY", Color("bbc5bd"), 8)
	label_at(Vector2(61, 118), "THUGS LEAVE YOU ALONE UNTIL YOU HIT THEM.", Color("90a9a2"), 7)

func draw_inventory() -> void:
	super.draw_inventory()
	# Supply count fits below equipped weapon and above the existing footer.
	label_at(Vector2(53, 128), "BANDAGES  %d / 9     B: HEAL 30 HP" % player.inventory.bandages, Color("c6d8b7"), 7)

func draw_custom_modal() -> bool:
	if not arena.service_open:
		return false
	draw_rect(Rect2(0, 30, 320, 127), Color(0.02, 0.03, 0.05, 0.86))
	draw_rect(Rect2(23, 43, 274, 106), Color("17252d"))
	draw_rect(Rect2(23, 43, 274, 106), Color("899d8d"), false)
	var heading: String
	var description: String
	var action: String
	match arena.location:
		"shop":
			heading = "CORNER SUPPLY"
			description = "BANDAGE / RESTORES 30 HP / CARRY UP TO 9"
			action = "1  BUY BANDAGE  $5    /    OWNED %d" % player.inventory.bandages
		"hospital":
			heading = "MERCY HOSPITAL"
			description = "WALK-IN CARE. NO CHARGE."
			action = "1  RESTORE FULL HEALTH"
		_:
			heading = "STREET BUSINESS"
			description = "WIN 3 FIGHTS. RETURN HERE FOR $25."
			match arena.mission.state:
				BarMission.State.AVAILABLE: action = "1  ACCEPT JOB"
				BarMission.State.ACTIVE: action = "%d / 3 WINS   /   JOB IN PROGRESS" % arena.mission.wins
				BarMission.State.READY: action = "1  CLAIM $25 REWARD"
				_: action = "JOB COMPLETE / REWARD PAID"
	label_at(Vector2(36, 61), heading, Color("ead8b5"), 12)
	draw_line(Vector2(36, 68), Vector2(284, 68), Color("496052"))
	label_at(Vector2(36, 81), description, Color("b6c9bc"), 7)
	label_at(Vector2(36, 101), action, Color("cce5ad"), 9)
	label_at(Vector2(36, 120), arena.service_message, Color("e0c7a0"), 7)
	label_at(Vector2(36, 139), "E / ESC CLOSE", Color("93a6a0"), 7)
	return true
