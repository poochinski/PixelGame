extends Node

var arena: Node2D
var player: CombatPlayer
var thug: StreetThug
var failures: int = 0
var checks: int = 0
var started_combos: Array[int] = []

func _ready() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame

func place_pair(at: Vector2 = Vector2(230, 170), enemy_at: Vector2 = Vector2(250, 170)) -> void:
	player.respawn(at)
	player.controls_enabled = false
	player.health.invulnerability = 0.0
	player.facing = Vector2.RIGHT
	thug.global_position = enemy_at
	thug.enabled = false
	thug.state = StreetThug.State.IDLE
	thug.stagger_left = 0.0
	thug.knockback = Vector2.ZERO
	thug.velocity = Vector2.ZERO
	thug.health.restore()
	thug.hitbox.end()

func run() -> void:
	arena = preload("res://levels/testing/CombatTest.tscn").instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	player = arena.player
	thug = arena.thug
	arena.auto_respawn_enemy = false
	CombatFX.hitstop_enabled = false
	thug.enabled = false
	await frames(3)
	check(is_instance_valid(player.health) and is_instance_valid(thug.hurtbox), "Player/enemy scenes share reusable combat components")
	# Exercise actual InputMap movement, including normalization and immediate release.
	thug.position = Vector2(400, 270)
	player.position = Vector2(200, 170)
	var start := player.position
	Input.action_press("move_right")
	await frames(30)
	Input.action_release("move_right")
	var straight := player.position.distance_to(start)
	check(straight > 41.0 and straight < 47.0, "Slower WASD pace moves about 44 pixels in half a second")
	start = player.position
	await frames(3)
	check(player.position.distance_to(start) < 0.1, "Movement stops immediately on release")
	player.position = Vector2(200, 170)
	start = player.position
	Input.action_press("move_right")
	Input.action_press("move_down")
	await frames(30)
	Input.action_release("move_right")
	Input.action_release("move_down")
	check(absf(player.position.distance_to(start) - straight) < 3.0, "Diagonal movement is normalized")
	await frames(2)
	var mouse := InputEventMouseMotion.new()
	mouse.position = Vector2(300, 90)
	get_viewport().push_input(mouse)
	await frames(2)
	check(player.facing.dot((player.get_global_mouse_position() - player.position).normalized()) > 0.99, "Player aims toward viewport mouse position")
	check(CombatFX.camera.position.distance_to(player.position + Vector2(0, -23)) < 27.0, "Camera smoothly follows with bounded look-ahead and northward framing")
	check(player.visual.ground_travel > 35.0, "Walk animation advances with actual ground travel")
	# Plant the actor during the windup, then keep feet anchored through the lunge.
	place_pair()
	await frames(3)
	player.controls_enabled = true
	player.weapon_controller.request(true)
	Input.action_press("move_right")
	await frames(2)
	var planted_at := player.position
	var loaded_frame := player.visual.animation_frame
	check(loaded_frame == ActorVisual.Frame.HEAVY_LOAD, "Heavy windup selects the raised bat frame")
	await frames(8)
	check(player.position.distance_to(planted_at) < 0.1, "Windup plants the character despite held movement input")
	await frames(15)
	check(player.position.distance_to(planted_at) < 0.2 and player.visual.animation_frame == loaded_frame and thug.health.current == 110.0, "Raised bat and planted position remain until heavy contact")
	Input.action_release("move_right")
	check(player.try_dodge(Vector2.DOWN), "Planted attacks can still be cancelled with dodge")
	check(not player.weapon_controller.presentation_pose().active, "Dodge cancellation clears the attack pose immediately")
	place_pair()
	await frames(3)
	player.weapon_controller.attack_started.connect(func(index: int, _heavy: bool) -> void: started_combos.append(index))
	player.weapon_controller.request()
	await frames(12)
	check(is_equal_approx(thug.health.current, 92.0), "First bat strike deals 18 damage exactly once")
	check(player.visual.animation_frame == ActorVisual.Frame.LIGHT_HIT, "Light contact sprite coincides with damage")
	check(thug.stagger_left > 0.0 and thug.flash_left > 0.0, "Impact applies visible stagger and hit flash")
	check(thug.knockback.x > 0.0, "Impact applies directional knockback")
	player.weapon_controller.request()
	await frames(25)
	player.weapon_controller.request()
	await frames(45)
	check(started_combos == [1, 2, 3], "Buffered light attacks execute all three combo steps")
	check(is_equal_approx(thug.health.current, 45.2), "Combo damage is 18 + 18 + 28.8, with no duplicate hits")
	await frames(40)
	thug.stagger_left = 0.0
	player.weapon_controller.request()
	check(player.weapon_controller.combo == 1, "Combo resets after the input window expires")
	player.weapon_controller.cancel()
	place_pair()
	await frames(3)
	player.weapon_controller.request(true)
	await frames(10)
	check(is_equal_approx(thug.health.current, 110.0), "Heavy attack has a real windup before dealing damage")
	await frames(18)
	check(is_equal_approx(thug.health.current, 66.8), "Heavy strike deals 43.2 damage")
	check(player.visual.animation_frame == ActorVisual.Frame.HEAVY_HIT, "Overhead slam sprite coincides with heavy damage")
	check(thug.stagger_left > 0.5 and thug.knockback.x > 100.0, "Heavy strike has stronger stagger and knockback")
	await frames(25)
	check(not player.weapon_controller.busy, "Heavy attack exits recovery cleanly")
	# Enemy behind the player must not be struck.
	place_pair(Vector2(230, 170), Vector2(207, 170))
	await frames(3)
	player.weapon_controller.request()
	await frames(23)
	check(is_equal_approx(thug.health.current, 110.0), "Melee sectors reject targets behind the player")
	# Reusable hitbox is occluded by solid world geometry.
	arena.add_wall(Rect2(238, 158, 4, 24))
	var occlusion_wall := arena.get_child(arena.get_child_count() - 1)
	place_pair()
	await frames(3)
	player.weapon_controller.request(true)
	await frames(44)
	check(is_equal_approx(thug.health.current, 110.0), "Solid walls block melee damage")
	occlusion_wall.queue_free()
	await frames(2)
	# Same-team hurtboxes are rejected.
	place_pair()
	thug.hurtbox.team = 0
	await frames(3)
	player.weapon_controller.request()
	await frames(23)
	check(is_equal_approx(thug.health.current, 110.0), "Hitboxes reject friendly fire")
	thug.hurtbox.team = 1
	place_pair(Vector2(230, 170), Vector2(400, 270))
	await frames(3)
	var hit := DamageData.new()
	hit.amount = 10.0
	hit.source = thug
	hit.direction = Vector2.LEFT
	var dodge_start := player.position
	check(player.try_dodge(Vector2.RIGHT), "Directional dodge can start when ready")
	check(not player.health.receive(hit), "Dodge invulnerability rejects damage")
	player.weapon_controller.request()
	check(not player.weapon_controller.busy, "Attacks are blocked during dodge")
	await frames(11)
	check(player.is_dodging() and player.health.receive(hit), "Invulnerability expires before the dodge ends")
	await frames(6)
	check(player.position.x - dodge_start.x > 39.0 and player.position.x - dodge_start.x < 52.0, "Dodge covers a shorter controlled burst distance")
	check(not player.try_dodge(Vector2.RIGHT), "Dodge cooldown prevents repeated dashes")
	await frames(32)
	check(player.try_dodge(Vector2.RIGHT), "Dodge becomes available after cooldown")
	place_pair(Vector2(454, 170), Vector2(400, 270))
	await frames(3)
	player.try_dodge(Vector2.RIGHT)
	await frames(18)
	check(player.position.x <= 459.1, "Dodge cannot pass through solid arena walls")
	player.controls_enabled = true
	Input.action_press("move_right")
	await frames(12)
	var blocked_travel := player.visual.ground_travel
	await frames(12)
	check(absf(player.visual.ground_travel - blocked_travel) < 0.1 and not player.visual.moving, "Pushing into a wall does not play a treadmill walk cycle")
	Input.action_release("move_right")
	# Observe actual displacement from a hit while AI is idle.
	place_pair()
	thug.enabled = true
	thug.target = null
	await frames(3)
	var enemy_start := thug.position
	hit.direction = Vector2.RIGHT
	hit.knockback = 150.0
	thug.health.receive(hit)
	await frames(10)
	check(thug.position.x > enemy_start.x + 8.0, "Knockback physically displaces enemies")
	# AI must reach the player despite an intervening dumpster.
	place_pair(Vector2(153, 150), Vector2(70, 150))
	thug.enabled = true
	thug.target = player
	var approached := false
	for i in range(270):
		await frames(1)
		if thug.position.distance_to(player.position) < 35.0:
			approached = true
			break
	check(approached, "Thug navigates around the dumpster and reaches player")
	# New spacing behavior must visibly circle before committing.
	place_pair(Vector2(230, 190), Vector2(275, 190))
	thug.enabled = true
	thug.target = player
	await frames(4)
	check(thug.state == StreetThug.State.CIRCLE, "Thug assesses and circles at medium range")
	var circle_start := thug.position
	await frames(16)
	check(absf(thug.position.y - circle_start.y) > 3.0 and player.health.current == 100.0, "Circling produces lateral movement without contact damage")
	# A sidestep after the telegraph locks must make the committed strike miss.
	place_pair()
	thug.enabled = true
	thug.target = player
	await frames(21)
	var locked_direction := thug.attack_direction
	player.position = Vector2(250, 205)
	await frames(3)
	check(thug.attack_direction.is_equal_approx(locked_direction), "Late windup locks aim rather than tracking the player")
	await frames(27)
	check(player.health.current == 100.0 and thug.state == StreetThug.State.RECOVER, "Sidestep makes the strike whiff and exposes a punish window")
	# Run enemy telegraph / melee attack through a complete cycle.
	place_pair()
	thug.enabled = true
	thug.target = player
	await frames(4)
	check(thug.state == StreetThug.State.WINDUP, "Thug telegraphs before striking")
	check(player.health.current == 100.0, "Telegraph does not deal early damage")
	await frames(39)
	check(player.health.current < 100.0, "Enemy melee strike damages player")
	# Lethal damage and actual arena recovery.
	hit.amount = 1000.0
	player.health.invulnerability = 0.0
	player.health.receive(hit)
	check(player.health.dead and arena.respawn_left > 0.0, "Player death begins respawn countdown")
	await frames(135)
	thug = arena.thug
	thug.enabled = false
	check(not player.health.dead and player.health.current == 100.0, "Player automatically respawns at full health")
	check(player.position.distance_to(arena.spawn) < 0.1, "Player respawns at arena checkpoint")
	thug.health.receive(hit)
	await frames(2)
	check(thug.health.dead and arena.kills == 1, "Enemy death increments KO counter")
	arena.auto_respawn_enemy = true
	await frames(140)
	check(is_instance_valid(arena.thug) and not arena.thug.health.dead, "Next Street Thug spawns for continued practice")
	# Pause/resume uses the always-processing HUD, exercising real event routing.
	var pause := InputEventAction.new()
	pause.action = "pause"
	pause.pressed = true
	get_viewport().push_input(pause)
	check(get_tree().paused, "Escape pauses the game")
	get_viewport().push_input(pause)
	check(not get_tree().paused, "Escape resumes from pause")
	Engine.time_scale = 1.0
	print("COMBAT TEST RESULTS: %d/%d passed" % [checks - failures, checks])
	get_tree().quit(1 if failures else 0)

