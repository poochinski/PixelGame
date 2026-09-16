extends Node

var viewport: SubViewport
var boards: Node2D
var actors: Array[CombatActor] = []
var failures: int = 0
var checks: int = 0
var team: int = 0

func _ready() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(832, 488)
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	boards = Node2D.new()
	viewport.add_child(boards)
	boards.draw.connect(draw_board)
	for current_team in range(2):
		team = current_team
		var source := RPGSpriteLibrary.sheet(team)
		check(source.get_image().get_pixel(0, 0).a == 0.0, "Atlas background must be transparent")
		for row in range(4):
			for column in range(8):
				var scene: PackedScene = preload("res://player/Player.tscn") if team == 0 else preload("res://enemies/StreetThug.tscn")
				var actor := scene.instantiate() as CombatActor
				actor.position = Vector2(64 + column * 100, 140 + row * 110)
				actor.scale = Vector2(2, 2)
				viewport.add_child(actor)
				actor.set_physics_process(false)
				if actor.weapon_controller:
					actor.weapon_controller.set_physics_process(false)
				actor.visual.preview_direction = row
				actor.visual.preview_frame = column
				actor.visual.update_presentation(0.0)
				var frame := actor.visual.texture as AtlasTexture
				check(Rect2(Vector2.ZERO, source.get_size()).encloses(frame.region) and frame.region.size.x > 0, "Sprite crop extends outside its source atlas")
				actors.append(actor)
		boards.queue_redraw()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://tests/rpg_%s_sheet.png" % ("player" if team == 0 else "thug"))
		for actor in actors:
			actor.queue_free()
		actors.clear()
		await get_tree().process_frame
	print("RPG ANIMATION REVIEW: %d/%d checks passed; 2 sheets cover all 32 poses per character." % [checks - failures, checks])
	get_tree().quit(1 if failures else 0)

func draw_board() -> void:
	boards.draw_rect(Rect2(0, 0, 832, 488), Color("151d2b"))
	var font := ThemeDB.fallback_font
	boards.draw_string(font, Vector2(12, 22), "SURVIVOR" if team == 0 else "STREET THUG", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ead0a3"))
	var labels := ["IDLE", "WALK A", "WALK B", "LOAD", "CONTACT", "FINISH", "RAISED", "SLAM"]
	for column in range(8):
		boards.draw_string(font, Vector2(34 + column * 100, 44), labels[column], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("9ebcb6"))
	for row in range(4):
		boards.draw_string(font, Vector2(4, 135 + row * 110), ["S", "W", "E", "N"][row], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("abb6c4"))
		boards.draw_line(Vector2(8, 149 + row * 110), Vector2(824, 149 + row * 110), Color("293444"))
