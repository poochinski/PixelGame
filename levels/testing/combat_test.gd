extends Node2D

const PlayerScene = preload("res://player/Player.tscn")
const ThugScene = preload("res://enemies/StreetThug.tscn")
const CameraScript = preload("res://player/combat_camera.gd")
const ArenaArt = preload("res://levels/testing/arena_art.gd")
const HUD = preload("res://ui/combat_hud.gd")
const Lighting = preload("res://levels/testing/arena_lighting.gd")
var player: CombatPlayer
var thug: StreetThug
var hud: Control
var loot: Node2D
var inventory_open: bool = false
var paused_before_inventory: bool = false
var kills: int = 0
var thug_wait: float = 0.0
var respawn_left: float = 0.0
var navigation := AStarGrid2D.new()
var spawn := Vector2(210, 174)
var auto_respawn_enemy: bool = true
var obstacles: Array[Rect2] = [Rect2(88, 138, 48, 24), Rect2(345, 211, 48, 24)]

func _ready() -> void:
	configure_inputs()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var art := ArenaArt.new()
	art.obstacles = obstacles
	add_child(art)
	for wall in [Rect2(0, 0, 480, 124), Rect2(0, 304, 480, 16), Rect2(0, 0, 16, 320), Rect2(464, 0, 16, 320)]:
		add_wall(wall)
	for obstacle in obstacles:
		add_wall(obstacle)
		var occluder := LightOccluder2D.new()
		var polygon := OccluderPolygon2D.new()
		polygon.polygon = PackedVector2Array([obstacle.position, Vector2(obstacle.end.x, obstacle.position.y), obstacle.end, Vector2(obstacle.position.x, obstacle.end.y)])
		occluder.occluder = polygon
		add_child(occluder)
	add_child(Lighting.new())
	build_navigation()
	loot = Node2D.new()
	loot.name = "Loot"
	add_child(loot)
	player = PlayerScene.instantiate()
	player.position = spawn
	add_child(player)
	player.health.died.connect(_player_died)
	var camera := CameraScript.new()
	camera.target = player
	camera.position = player.position + Vector2(0, -23)
	add_child(camera)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = HUD.new()
	hud.player = player
	hud.arena = self
	layer.add_child(hud)
	spawn_thug()
	if OS.get_cmdline_user_args().has("--capture"):
		_capture.call_deferred()

func configure_inputs() -> void:
	var keys := {"move_up": KEY_W, "move_down": KEY_S, "move_left": KEY_A, "move_right": KEY_D, "dodge": KEY_SPACE, "reset_arena": KEY_R, "pause": KEY_ESCAPE, "debug": KEY_F1, "inventory": KEY_I}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event := InputEventKey.new()
			event.physical_keycode = keys[action]
			InputMap.action_add_event(action, event)
	for action in {"primary_attack": MOUSE_BUTTON_LEFT, "secondary_attack": MOUSE_BUTTON_RIGHT}:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT if action == "primary_attack" else MOUSE_BUTTON_RIGHT
			InputMap.action_add_event(action, event)

func add_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 0
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collider.shape = shape
	body.add_child(collider)
	add_child(body)

func build_navigation() -> void:
	navigation.region = Rect2i(0, 0, 60, 40)
	navigation.cell_size = Vector2(8, 8)
	navigation.offset = Vector2(4, 4)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for y in range(40):
		for x in range(60):
			var point := Vector2(x * 8 + 4, y * 8 + 4)
			var solid := not Rect2(24, 132, 432, 164).has_point(point)
			for obstacle in obstacles:
				solid = solid or obstacle.grow(7).has_point(point)
			navigation.set_point_solid(Vector2i(x, y), solid)

func spawn_thug() -> void:
	if is_instance_valid(thug):
		thug.queue_free()
	thug = ThugScene.instantiate()
	var candidates: Array[Vector2] = [Vector2(289, 174), Vector2(180, 252), Vector2(308, 252), Vector2(65, 220)]
	var at := candidates[0]
	for candidate in candidates:
		if candidate.distance_to(player.position) > 75.0:
			at = candidate
			break
	thug.position = at
	thug.target = player
	thug.navigation = navigation
	add_child(thug)
	thug.health.died.connect(_thug_died)
	thug.money_dropped.connect(spawn_money)

func spawn_money(amount: int, at: Vector2) -> MoneyPickup:
	var pickup := MoneyPickup.new()
	pickup.amount = amount
	pickup.position = at
	pickup.collector = player
	loot.add_child(pickup)
	return pickup

func _physics_process(delta: float) -> void:
	if respawn_left > 0.0:
		respawn_left -= delta
		if respawn_left <= 0.0:
			reset_arena(false)
	elif thug_wait > 0.0 and auto_respawn_enemy:
		thug_wait -= delta
		if thug_wait <= 0.0:
			spawn_thug()

func handle_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("inventory") and not player.health.dead:
		if inventory_open:
			close_inventory()
		else:
			paused_before_inventory = get_tree().paused
			inventory_open = true
			get_tree().paused = true
		return
	if event.is_action_pressed("pause"):
		if inventory_open:
			close_inventory()
		else:
			get_tree().paused = not get_tree().paused
	if event.is_action_pressed("reset_arena"):
		get_tree().paused = false
		reset_arena(true)
	if event.is_action_pressed("debug"):
		hud.debug_visible = not hud.debug_visible
		player.weapon_controller.hitbox.debug_visible = hud.debug_visible
		if is_instance_valid(thug):
			thug.hitbox.debug_visible = hud.debug_visible

func close_inventory() -> void:
	inventory_open = false
	get_tree().paused = paused_before_inventory

func _player_died() -> void:
	respawn_left = 2.0
	thug_wait = 0.0
	CombatFX.sound("death")

func _thug_died() -> void:
	kills += 1
	thug_wait = 2.2

func reset_arena(clear_score: bool = true) -> void:
	inventory_open = false
	get_tree().paused = false
	for pickup in loot.get_children():
		pickup.collected = true
		pickup.queue_free()
	Engine.time_scale = 1.0
	CombatFX.hitstop_until = 0
	respawn_left = 0.0
	thug_wait = 0.0
	if clear_score:
		kills = 0
	player.respawn(spawn)
	spawn_thug()

func _capture() -> void:
	player.controls_enabled = false
	player.facing = Vector2.RIGHT
	thug.enabled = false
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tests/combat_preview.png")
	print("CAPTURE SAVED")
	get_tree().quit()
