extends Node

var arena: Node2D
var player: CombatPlayer
var thug: StreetThug
var errors: int = 0

func _ready() -> void:
	run.call_deferred()

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tests/" + filename + ".png")

func run() -> void:
	arena = preload("res://levels/testing/CombatTest.tscn").instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	player = arena.player
	thug = arena.thug
	arena.auto_respawn_enemy = false
	thug.enabled = false
	player.controls_enabled = false
	player.position = Vector2(230, 170)
	thug.position = Vector2(254, 170)
	player.facing = Vector2.RIGHT
	await wait(0.3)
	player.weapon_controller.request(true)
	await wait(0.20)
	await capture("heavy_windup")
	for i in range(90):
		await get_tree().process_frame
		if thug.health.current < 110.0:
			break
	await capture("heavy_impact")
	if Engine.time_scale >= 1.0:
		push_error("Heavy hit-stop did not activate")
		errors += 1
	await wait(0.15)
	if Engine.time_scale != 1.0:
		push_error("Hit-stop did not release")
		errors += 1
	await wait(0.5)
	player.try_dodge(Vector2.DOWN)
	await wait(0.09)
	await capture("dodge_trail")
	await wait(0.9)
	arena.reset_arena()
	thug = arena.thug
	thug.enabled = false
	thug.position = Vector2(254, 174)
	player.controls_enabled = true
	var mouse := InputEventMouseMotion.new()
	mouse.position = Vector2(255, 90)
	get_viewport().push_input(mouse)
	await wait(0.05)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(255, 90)
	Input.parse_input_event(click)
	await wait(0.05)
	click.pressed = false
	Input.parse_input_event(click)
	if not player.weapon_controller.busy:
		push_error("Real mouse button event did not start attack")
		errors += 1
	await wait(0.4)
	# Leave a representative title / arena screenshot with both actors visible.
	player.controls_enabled = false
	player.position = Vector2(210, 174)
	thug.position = Vector2(270, 174)
	player.facing = Vector2.RIGHT
	await wait(0.5)
	await capture("combat_preview")
	for direction in [Vector2.UP, Vector2.LEFT, Vector2.DOWN]:
		player.facing = direction
		await wait(0.08)
		await capture("grip_" + ("north" if direction == Vector2.UP else "west" if direction == Vector2.LEFT else "south"))
	print("RENDERED FEEDBACK TEST: ", "PASS" if errors == 0 else "FAIL", " | heavy hit-stop, recovery, mouse input, impact and dodge captures")
	await wait(0.25)
	get_tree().quit(errors)
