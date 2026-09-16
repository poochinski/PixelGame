extends Node

var arena: Node2D
var player: CombatPlayer
var checks: int = 0
var failures: int = 0

func _ready() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame

func key(code: Key, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	event.echo = echo
	get_viewport().push_input(event)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	get_viewport().push_input(event)

func capture(filename: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/" + filename + ".png")

func run() -> void:
	seed(1741)
	arena = preload("res://levels/testing/CombatTest.tscn").instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	arena.auto_respawn_enemy = false
	CombatFX.hitstop_enabled = false
	player = arena.player
	player.controls_enabled = false
	player.position = Vector2(190, 190)
	arena.thug.enabled = false
	arena.thug.position = Vector2(250, 190)
	await frames(3)
	check(player.inventory.cash == 0, "Fresh player inventory starts with zero cash")
	check(not player.inventory.add_cash(0) and not player.inventory.add_cash(-5) and player.inventory.cash == 0, "Invalid credits cannot alter the wallet")
	var hit := DamageData.new()
	hit.amount = 1
	hit.source = player
	hit.direction = Vector2.RIGHT
	arena.thug.health.receive(hit)
	check(arena.loot.get_child_count() == 0, "Nonlethal damage does not create loot")
	hit.amount = 1000
	arena.thug.health.receive(hit)
	check(arena.loot.get_child_count() == 1, "A thug death creates exactly one money drop")
	var drop := arena.loot.get_child(0) as MoneyPickup
	var amount := drop.amount
	check(amount >= 1 and amount <= 10, "Drop amount is between one and ten whole dollars")
	check(player.inventory.cash == 0, "Dropping money does not credit it before collection")
	check(not arena.thug.health.receive(hit) and arena.loot.get_child_count() == 1, "Repeated hits on a dead thug cannot create more drops")
	await frames(60)
	check(is_instance_valid(drop) and player.inventory.cash == 0, "Money waits on the ground while the player is out of range")
	await capture("money_on_ground")
	arena.spawn_thug()
	arena.thug.enabled = false
	arena.thug.position = Vector2(400, 270)
	await frames(3)
	check(is_instance_valid(drop), "Money outlives the dead thug when a new enemy spawns")
	player.controls_enabled = true
	Input.action_press("move_right")
	await frames(40)
	Input.action_release("move_right")
	player.controls_enabled = false
	await frames(2)
	check(player.inventory.cash == amount and not is_instance_valid(drop), "Walking over money credits its exact amount and removes it")
	check(arena.hud.cash_notice == "+$%d COLLECTED" % amount, "HUD confirms the collected amount")
	await capture("money_collected")
	key(KEY_I)
	check(arena.inventory_open and get_tree().paused, "I opens inventory and pauses combat")
	var paused_position := player.position
	for i in range(3):
		await get_tree().process_frame
	check(player.position == paused_position, "Inventory freezes world movement")
	await capture("inventory_preview")
	key(KEY_I, true)
	check(arena.inventory_open, "Held inventory key does not repeatedly toggle the panel")
	key(KEY_ESCAPE)
	check(not arena.inventory_open and not get_tree().paused, "Escape closes inventory and resumes combat")
	key(KEY_ESCAPE)
	key(KEY_I)
	check(arena.inventory_open and get_tree().paused, "Inventory can be inspected from the pause menu")
	key(KEY_I)
	check(not arena.inventory_open and get_tree().paused, "Closing inventory preserves an existing pause")
	key(KEY_ESCAPE)
	var before := player.inventory.cash
	drop = arena.spawn_money(10, player.position)
	check(not drop.try_collect() and player.inventory.cash == before, "New drops finish their bounce before pickup")
	drop.age = 1.0
	check(drop.try_collect() and not drop.try_collect() and player.inventory.cash == before + 10, "Two pickup attempts in one frame only pay once")
	await frames(2)
	before = player.inventory.cash
	player.position = Vector2(230, 190)
	arena.add_wall(Rect2(237, 180, 2, 20))
	var wall := arena.get_child(arena.get_child_count() - 1)
	drop = arena.spawn_money(5, Vector2(240, 190))
	drop.age = 1.0
	await frames(3)
	check(is_instance_valid(drop) and player.inventory.cash == before, "Nearby money cannot be collected through a wall")
	wall.queue_free()
	await frames(3)
	check(not is_instance_valid(drop) and player.inventory.cash == before + 5, "Unobstructed nearby money can be collected")
	before = player.inventory.cash
	player.health.invulnerability = 0.0
	player.health.receive(hit)
	drop = arena.spawn_money(9, player.position)
	drop.age = 1.0
	check(not drop.try_collect() and player.inventory.cash == before, "Dead players cannot collect money")
	key(KEY_I)
	check(not arena.inventory_open, "Inventory cannot pause the death respawn countdown")
	await frames(135)
	arena.thug.enabled = false
	check(not player.health.dead and player.inventory.cash == before, "Collected cash survives player death and respawn")
	check(arena.loot.get_child_count() == 0, "Respawn clears uncollected money from the reset encounter")
	arena.spawn_money(3, Vector2(300, 270))
	key(KEY_I)
	key(KEY_R)
	arena.thug.enabled = false
	await frames(3)
	check(not arena.inventory_open and not get_tree().paused and arena.loot.get_child_count() == 0 and player.inventory.cash == before, "R resets the encounter, closes inventory and preserves collected cash")
	# Exercise the actual death signal across many new enemies with a fixed seed.
	player.position = Vector2(50, 280)
	var amounts: Dictionary = {}
	var valid_drops := true
	for i in range(64):
		arena.spawn_thug()
		arena.thug.enabled = false
		arena.thug.position = Vector2(300, 174)
		arena.thug.health.receive(hit)
		var payout := arena.loot.get_child(arena.loot.get_child_count() - 1) as MoneyPickup
		valid_drops = valid_drops and payout.amount >= 1 and payout.amount <= 10
		amounts[payout.amount] = true
		await frames(1)
	check(valid_drops and arena.loot.get_child_count() == 64, "64 thug deaths each produce one valid cash drop")
	check(amounts.size() > 1, "Thug payouts vary across deaths")
	check(player.inventory.cash == before, "Uncollected random drops do not change cash")
	var fresh := PlayerInventory.new()
	add_child(fresh)
	check(fresh.cash == 0, "A new inventory does not inherit another player's balance")
	fresh.queue_free()
	print("LOOT TEST RESULTS: %d/%d passed" % [checks - failures, checks])
	get_tree().quit(1 if failures else 0)
