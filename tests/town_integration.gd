extends Node

var town: Node2D
var player: CombatPlayer
var failures: int = 0
var checks: int = 0

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

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	get_viewport().push_input(event)
	event = InputEventKey.new()
	event.physical_keycode = code
	get_viewport().push_input(event)

func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/town_" + name + ".png")

func enter(id: String) -> void:
	player.position = TownLayout.door_for(id)
	player.velocity = Vector2.ZERO
	player.knockback = Vector2.ZERO
	key(KEY_E)
	await frames(3)
	check(town.location == id and town.rooms[id].visible and not town.world.visible, "%s door enters its own interior" % id)

func counter() -> void:
	player.controls_enabled = true
	Input.action_press("move_up")
	await frames(40)
	Input.action_release("move_up")
	player.controls_enabled = false
	await frames(2)
	key(KEY_E)
	check(town.service_open and get_tree().paused, "Walking to the counter and pressing E opens a paused service panel")

func leave() -> void:
	if town.service_open:
		key(KEY_ESCAPE)
	var previous: String = town.location
	player.position = TownLayout.ROOM_ORIGINS[previous] + Vector2(160, 198)
	key(KEY_E)
	await frames(3)
	check(town.location == "town" and town.world.visible and player.position.distance_to(TownLayout.door_for(previous)) < 15, "Interior exit returns to the matching street doorway")

func run() -> void:
	town = preload("res://levels/town/Town.tscn").instantiate()
	get_tree().root.add_child(town)
	get_tree().current_scene = town
	player = town.player
	player.controls_enabled = false
	CombatFX.hitstop_enabled = false
	await frames(20)
	check(town.rooms.size() == 3 and town.enemies.size() == 4, "Town creates three distinct interiors and four street thugs")
	var routes_open := true
	for building in TownLayout.BUILDINGS:
		var path: PackedVector2Array = town.navigation.get_point_path(Vector2i(player.position / 8), Vector2i(building.door / 8))
		routes_open = routes_open and not path.is_empty()
	check(routes_open, "All three doorways have traversable routes from the town spawn")
	await capture("street")
	var enemy: StreetThug = town.enemies[0]
	player.position = enemy.position - Vector2(20, 0)
	await frames(120)
	check(not enemy.hostile and enemy.state == StreetThug.State.IDLE and player.health.current == 100, "Standing beside a neutral thug does not start combat")
	player.facing = Vector2.LEFT
	player.weapon_controller.request()
	await frames(40)
	check(not enemy.hostile, "A missed swing does not provoke the thug")
	player.facing = Vector2.RIGHT
	player.weapon_controller.request()
	await frames(14)
	check(enemy.hostile and enemy.health.current < 110, "An actual bat hit provokes the struck thug")
	check(not town.enemies[1].hostile and not town.enemies[2].hostile, "Uninvolved thugs remain peaceful")
	player.weapon_controller.cancel()
	await frames(170)
	check(player.health.current < 100, "Provoked thug retaliates with its melee AI")
	var hit := DamageData.new()
	hit.source = player
	hit.amount = 1000
	hit.direction = Vector2.RIGHT
	enemy.health.receive(hit)
	await frames(2)
	check(town.loot.get_child_count() == 1 and town.mission.wins == 0, "Defeat drops money but does not advance an unaccepted mission")
	player.health.restore()
	player.stagger_left = 0
	player.knockback = Vector2.ZERO
	await enter("shop")
	check(not player.weapon_controller.enabled, "Interior disables combat attacks")
	await capture("shop_room")
	var exit_screen: Vector2 = town.camera.get_canvas_transform() * (TownLayout.ROOM_ORIGINS.shop + Vector2(160, 201))
	check(exit_screen.y < 157 and exit_screen.y > 30, "Interior exit remains visible between the HUD bars")
	var enemy_position: Vector2 = town.enemies[1].position
	await frames(4)
	check(town.enemies[1].position == enemy_position, "Street actors remain frozen while inside a building")
	await counter()
	key(KEY_1)
	check(player.inventory.cash == 0 and player.inventory.bandages == 0, "Shop refuses an unaffordable purchase without changing inventory")
	player.inventory.add_cash(10)
	key(KEY_1)
	key(KEY_1)
	check(player.inventory.cash == 0 and player.inventory.bandages == 2, "Two $5 purchases debit exactly $10 and grant two bandages")
	await capture("shop_menu")
	key(KEY_ESCAPE)
	player.health.current = 65
	key(KEY_B)
	check(player.health.current == 95 and player.inventory.bandages == 1, "B consumes one bandage and heals thirty HP")
	key(KEY_B)
	check(player.health.current == 100 and player.inventory.bandages == 0, "Bandage healing clamps to maximum health")
	player.inventory.add_cash(80)
	key(KEY_E)
	for i in range(9):
		key(KEY_1)
	var cash: int = player.inventory.cash
	key(KEY_1)
	check(player.inventory.bandages == 9 and player.inventory.cash == cash, "Full supply capacity rejects purchase without charging")
	key(KEY_ESCAPE)
	key(KEY_B)
	check(player.inventory.bandages == 9, "Full-health players do not waste a bandage")
	key(KEY_I)
	player.health.current = 40
	key(KEY_B)
	check(town.inventory_open and player.health.current == 70 and player.inventory.bandages == 8, "Bandages can be used from the paused inventory")
	await capture("inventory")
	key(KEY_ESCAPE)
	await leave()
	check(player.inventory.bandages == 8 and player.inventory.cash == cash, "Cash and supplies persist across room transitions")
	check(player.weapon_controller.enabled, "Leaving an interior re-enables combat")
	await enter("hospital")
	await capture("hospital_room")
	await counter()
	key(KEY_1)
	check(player.health.current == 100 and player.inventory.cash == cash, "Hospital restores full health for free")
	key(KEY_1)
	check(player.health.current == 100 and player.inventory.cash == cash, "Repeated full-health treatment does not change cash or health")
	await capture("hospital_menu")
	await leave()
	await enter("bar")
	await capture("bar_room")
	await counter()
	key(KEY_1)
	check(town.mission.state == BarMission.State.ACTIVE and town.mission.wins == 0, "Bar accepts the first mission without counting earlier fights")
	key(KEY_1)
	check(player.inventory.cash == cash and town.mission.state == BarMission.State.ACTIVE, "Incomplete mission cannot pay out or restart")
	await capture("bar_menu")
	await leave()
	for i in range(1, 4):
		town.enemies[i].health.receive(hit)
	await frames(2)
	check(town.mission.state == BarMission.State.READY and town.mission.wins == 3, "Three post-acceptance victories complete the mission objective")
	check(town.loot.get_child_count() == 4, "Town combat preserves the existing money drops")
	await enter("bar")
	await counter()
	cash = player.inventory.cash
	key(KEY_1)
	check(player.inventory.cash == cash + 25 and town.mission.state == BarMission.State.COMPLETE, "Returning to the bar pays the $25 mission reward")
	key(KEY_1)
	check(player.inventory.cash == cash + 25, "Completed mission cannot pay twice")
	await capture("mission_paid")
	await leave()
	# Reset a single slot to check neutral replacement and death recovery.
	town.spawn_thug(0)
	check(not town.enemies[0].hostile, "Replacement town thugs start neutral")
	cash = player.inventory.cash
	var bandages: int = player.inventory.bandages
	player.health.invulnerability = 0
	player.health.receive(hit)
	await frames(135)
	check(town.location == "hospital" and not player.health.dead and player.health.current == 100, "Player death recovers safely inside the hospital")
	check(player.inventory.cash == cash and player.inventory.bandages == bandages and town.mission.state == BarMission.State.COMPLETE, "Death preserves wallet, supplies and mission state")
	check(not town.enemies[0].hostile and not town.enemies[1].hostile, "Recovery resets street hostilities")
	key(KEY_ESCAPE)
	check(get_tree().paused, "Town pause works")
	key(KEY_I)
	key(KEY_I)
	check(get_tree().paused and not town.inventory_open, "Inventory preserves a pre-existing town pause")
	key(KEY_ESCAPE)
	await leave()
	# Physical blockers and interaction range, not just scene switching.
	player.position = Vector2(384, 225)
	player.controls_enabled = true
	Input.action_press("move_up")
	await frames(25)
	Input.action_release("move_up")
	player.controls_enabled = false
	check(player.position.y >= 212.9, "Building facade blocks walking through its wall")
	player.position = Vector2(384, 300)
	key(KEY_E)
	check(town.location == "town" and not town.service_open, "Interaction cannot enter a building from across the street")
	print("TOWN TEST RESULTS: %d/%d passed" % [checks - failures, checks])
	get_tree().quit(1 if failures else 0)
