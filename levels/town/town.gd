extends Node2D

const ROOM_SCENES := {"shop": preload("res://levels/interiors/Shop.tscn"), "hospital": preload("res://levels/interiors/Hospital.tscn"), "bar": preload("res://levels/interiors/Bar.tscn")}
var player: CombatPlayer
var camera: Camera2D
var hud: Control
var world: Node2D
var loot: Node2D
var rooms: Dictionary = {}
var enemies: Array[StreetThug] = []
var respawn_timers: Array[float] = []
var navigation := AStarGrid2D.new()
var mission := BarMission.new()
var location: String = "town"
var interaction_prompt: String = ""
var service_open: bool = false
var service_message: String = ""
var inventory_open: bool = false
var paused_before_inventory: bool = false
var kills: int = 0
var thug: StreetThug
var thug_wait: float = 0.0
var respawn_left: float = 0.0

func _ready() -> void:
	configure_inputs()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	world = Node2D.new()
	world.name = "Neighborhood"
	add_child(world)
	world.add_child(preload("res://levels/town/town_art.gd").new())
	for rect in [Rect2(0, 0, 768, 16), Rect2(0, 464, 768, 16), Rect2(0, 0, 16, 480), Rect2(752, 0, 16, 480)]:
		TownLayout.wall(world, rect)
	for building in TownLayout.BUILDINGS:
		TownLayout.wall(world, building.rect)
	for rect in TownLayout.PROPS:
		TownLayout.wall(world, rect)
	build_navigation()
	loot = Node2D.new()
	loot.name = "Loot"
	world.add_child(loot)
	for id in ROOM_SCENES:
		var room: Node2D = ROOM_SCENES[id].instantiate()
		room.position = TownLayout.ROOM_ORIGINS[id]
		add_child(room)
		room.hide()
		room.process_mode = Node.PROCESS_MODE_DISABLED
		rooms[id] = room
	player = preload("res://player/Player.tscn").instantiate()
	player.position = Vector2(384, 256)
	add_child(player)
	player.health.died.connect(_player_died)
	camera = preload("res://player/combat_camera.gd").new()
	camera.target = player
	camera.bounds = Rect2(160, 90, 448, 300)
	camera.framing_offset = Vector2(0, -52)
	camera.position = player.position + camera.framing_offset
	add_child(camera)
	for index in range(TownLayout.THUG_SPAWNS.size()):
		enemies.append(null)
		respawn_timers.append(0.0)
		spawn_thug(index)
	thug = enemies[0]
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = preload("res://ui/town_hud.gd").new()
	hud.arena = self
	hud.player = player
	layer.add_child(hud)
	hud.notify("SHOP WEST / BAR EAST / HOSPITAL NORTH")
	update_interaction()

func configure_inputs() -> void:
	var keys := {"interact": KEY_E, "use_bandage": KEY_B, "service_confirm": KEY_1}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event := InputEventKey.new()
			event.physical_keycode = keys[action]
			InputMap.action_add_event(action, event)

func build_navigation() -> void:
	navigation.region = Rect2i(0, 0, 96, 60)
	navigation.cell_size = Vector2(8, 8)
	navigation.offset = Vector2(4, 4)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for y in range(60):
		for x in range(96):
			var p := Vector2(x * 8 + 4, y * 8 + 4)
			var solid := not Rect2(24, 24, 720, 432).has_point(p)
			for building in TownLayout.BUILDINGS:
				solid = solid or building.rect.grow(7).has_point(p)
			for rect in TownLayout.PROPS:
				solid = solid or rect.grow(7).has_point(p)
			navigation.set_point_solid(Vector2i(x, y), solid)

func spawn_thug(index: int) -> void:
	if is_instance_valid(enemies[index]):
		enemies[index].queue_free()
	var enemy := preload("res://enemies/StreetThug.tscn").instantiate() as StreetThug
	enemy.position = TownLayout.THUG_SPAWNS[index]
	enemy.starts_hostile = false
	enemy.target = player
	enemy.navigation = navigation
	enemy.facing = [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.DOWN][index]
	world.add_child(enemy)
	enemy.money_dropped.connect(spawn_money)
	enemy.health.died.connect(_thug_died.bind(index))
	enemies[index] = enemy
	respawn_timers[index] = 0.0

func spawn_money(amount: int, at: Vector2) -> void:
	var pickup := MoneyPickup.new()
	pickup.position = at
	pickup.amount = amount
	pickup.collector = player
	loot.add_child(pickup)

func _thug_died(index: int) -> void:
	kills += 1
	respawn_timers[index] = 18.0
	mission.record_win()
	if mission.state == BarMission.State.READY:
		hud.notify("JOB DONE. RETURN TO THE BAR.")

func _player_died() -> void:
	respawn_left = 2.0
	CombatFX.sound("death")

func _physics_process(delta: float) -> void:
	if respawn_left > 0.0:
		respawn_left -= delta
		if respawn_left <= 0.0:
			for i in range(enemies.size()):
				spawn_thug(i)
			player.respawn(Vector2.ZERO)
			change_location("hospital")
			hud.notify("RECOVERED AT MERCY HOSPITAL")
	if location == "town":
		for i in range(enemies.size()):
			if respawn_timers[i] > 0.0:
				respawn_timers[i] = maxf(0.01, respawn_timers[i] - delta)
				if respawn_timers[i] <= 0.01 and player.position.distance_to(TownLayout.THUG_SPAWNS[i]) > 95.0:
					spawn_thug(i)
		thug = enemies[0]
	update_interaction()

func nearby_interaction() -> String:
	if player.health.dead:
		return ""
	if location == "town":
		for building in TownLayout.BUILDINGS:
			if player.position.distance_to(building.door) <= 23.0:
				return building.id
	else:
		var local: Vector2 = player.position - TownLayout.ROOM_ORIGINS[location]
		if local.distance_to(Vector2(160, 201)) <= 23.0:
			return "exit"
		if local.distance_to(Vector2(160, 108)) <= 25.0:
			return "service"
	return ""

func update_interaction() -> void:
	var id := nearby_interaction()
	interaction_prompt = ""
	if id == "exit":
		interaction_prompt = "E  RETURN TO MERCY ROW"
	elif id == "service":
		interaction_prompt = "E  BUY SUPPLIES" if location == "shop" else "E  GET TREATMENT" if location == "hospital" else "E  CHECK THE JOB BOARD"
	else:
		for building in TownLayout.BUILDINGS:
			if id == building.id:
				interaction_prompt = "E  ENTER " + building.name

func interact() -> void:
	if player.health.dead or get_tree().paused:
		return
	var id := nearby_interaction()
	if id.is_empty():
		return
	if id == "exit":
		change_location("town")
	elif id == "service":
		service_open = true
		service_message = ""
		get_tree().paused = true
	else:
		change_location(id)

func change_location(destination: String) -> void:
	if destination != "town" and not rooms.has(destination):
		return
	var previous := location
	location = destination
	player.weapon_controller.cancel()
	player.weapon_controller.enabled = location == "town"
	player.velocity = Vector2.ZERO
	player.knockback = Vector2.ZERO
	player.dodge_left = 0.0
	world.visible = location == "town"
	world.process_mode = Node.PROCESS_MODE_INHERIT if location == "town" else Node.PROCESS_MODE_DISABLED
	for id in rooms:
		rooms[id].visible = id == location
		rooms[id].process_mode = Node.PROCESS_MODE_INHERIT if id == location else Node.PROCESS_MODE_DISABLED
	if location == "town":
		player.position = TownLayout.door_for(previous) + Vector2(0, 9)
		camera.bounds = Rect2(160, 90, 448, 300)
		camera.framing_offset = Vector2(0, -52)
		player.facing = Vector2.DOWN
	else:
		var origin: Vector2 = TownLayout.ROOM_ORIGINS[location]
		player.position = origin + Vector2(160, 171)
		camera.bounds = Rect2(origin + Vector2(160, 90), Vector2(0, 56))
		camera.framing_offset = Vector2(0, -23)
		player.facing = Vector2.UP
	camera.position = player.position + camera.framing_offset
	camera.position.x = clampf(camera.position.x, camera.bounds.position.x, camera.bounds.end.x)
	camera.position.y = clampf(camera.position.y, camera.bounds.position.y, camera.bounds.end.y)
	camera.trauma = 0.0
	camera.offset = Vector2.ZERO
	camera.force_update_scroll()
	player.visual.initialized = false
	update_interaction()

func service_action() -> void:
	if not service_open or nearby_interaction() != "service" or player.health.dead:
		return
	match location:
		"shop":
			if player.inventory.buy_bandage():
				service_message = "BOUGHT A BANDAGE. PRESS B TO USE."
				CombatFX.sound("cash")
			else:
				service_message = "BAG FULL (9 BANDAGES)." if player.inventory.bandages >= 9 else "YOU NEED $5 FOR A BANDAGE."
		"hospital":
			if player.health.current < player.health.maximum:
				player.health.heal(player.health.maximum)
				service_message = "ALL PATCHED UP. TAKE CARE OUT THERE."
			else:
				service_message = "YOU ARE ALREADY AT FULL HEALTH."
		"bar":
			if mission.accept():
				service_message = "JOB ACCEPTED. COME BACK AFTER 3 WINS."
			elif mission.claim(player.inventory):
				service_message = "JOB PAID. $25 ADDED TO YOUR CASH."
				CombatFX.sound("cash")
			else:
				service_message = "THIS JOB HAS ALREADY BEEN PAID." if mission.state == BarMission.State.COMPLETE else "%d / 3 WINS. KEEP AT IT." % mission.wins

func handle_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if service_open:
		if event.is_action_pressed("pause") or event.is_action_pressed("interact"):
			service_open = false
			get_tree().paused = false
		elif event.is_action_pressed("service_confirm"):
			service_action()
		return
	if event.is_action_pressed("inventory") and not player.health.dead:
		if inventory_open:
			inventory_open = false
			get_tree().paused = paused_before_inventory
		else:
			paused_before_inventory = get_tree().paused
			inventory_open = true
			get_tree().paused = true
	elif event.is_action_pressed("pause"):
		if inventory_open:
			inventory_open = false
			get_tree().paused = paused_before_inventory
		else:
			get_tree().paused = not get_tree().paused
	elif event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("use_bandage") and (not get_tree().paused or inventory_open):
		if not player.weapon_controller.busy and player.inventory.use_bandage(player.health):
			hud.notify("BANDAGE USED  /  +30 HEALTH")
		else:
			hud.notify("NO BANDAGES" if player.inventory.bandages == 0 else "CANNOT USE A BANDAGE RIGHT NOW")
	elif event.is_action_pressed("debug"):
		hud.debug_visible = not hud.debug_visible
		player.weapon_controller.hitbox.debug_visible = hud.debug_visible
		for enemy in enemies:
			enemy.hitbox.debug_visible = hud.debug_visible
