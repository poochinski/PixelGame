class_name ActorVisual
extends Node2D

# Direction rows follow conventional RPG character sheets: down, left, right, up.
enum Direction { SOUTH, WEST, EAST, NORTH }
enum Frame { IDLE, WALK_LEFT, WALK_RIGHT, LIGHT_LOAD, LIGHT_HIT, LIGHT_FINISH, HEAVY_LOAD, HEAVY_HIT }

var actor: CombatActor
var sprite: Sprite2D
var texture: Texture2D
var pose := CombatPose.new()
var direction: Direction = Direction.SOUTH
var animation_frame: int = Frame.IDLE
var ground_travel: float = 0.0
var moving: bool = false
var previous_position := Vector2.ZERO
var initialized: bool = false
var preview_direction: int = -1
var preview_frame: int = -1

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	update_presentation(0.0)

static func facing_row(facing: Vector2) -> Direction:
	if absf(facing.x) > absf(facing.y):
		return Direction.WEST if facing.x < 0.0 else Direction.EAST
	return Direction.NORTH if facing.y < 0.0 else Direction.SOUTH

func update_presentation(_delta: float) -> void:
	pose = actor.presentation_pose()
	var displacement := actor.global_position - previous_position
	if not initialized or displacement.length() > 32.0:
		initialized = true
		displacement = Vector2.ZERO
		ground_travel = 0.0
	previous_position = actor.global_position
	var can_walk := not pose.active or (pose.phase == 3 and pose.progress > 0.65)
	moving = displacement.length() > 0.12 and can_walk and not actor.health.dead and not actor.is_dodging()
	direction = facing_row(pose.aim)
	if moving:
		# Walking faces the direction of travel; attacks face the mouse aim.
		direction = facing_row(displacement)
		ground_travel += displacement.length()
		animation_frame = [Frame.WALK_LEFT, Frame.IDLE, Frame.WALK_RIGHT, Frame.IDLE][int(ground_travel / 10.0) % 4]
	else:
		animation_frame = attack_frame()
	if actor.is_dodging():
		direction = facing_row(actor.velocity)
		animation_frame = Frame.WALK_LEFT
	if preview_frame >= 0:
		animation_frame = preview_frame
		direction = preview_direction as Direction
	texture = RPGSpriteLibrary.frame(actor.team, direction, animation_frame)
	sprite.texture = texture
	sprite.scale = RPGSpriteLibrary.render_scale(actor.team)
	sprite.position = RPGSpriteLibrary.sprite_offset(actor.team, direction, animation_frame)
	sprite.flip_h = false
	sprite.rotation = -PI * 0.5 if actor.health.dead else 0.0
	if actor.health.dead:
		sprite.position = Vector2(0, -7)
	sprite.modulate = Color(3, 3, 3) if actor.flash_left > 0.0 else Color("a1e6da") if actor.is_dodging() else Color("81727c") if actor.health.dead else Color.WHITE
	queue_redraw()

func _process(delta: float) -> void:
	update_presentation(delta)

func attack_frame() -> int:
	if actor.health.dead or not pose.active:
		return Frame.IDLE
	if pose.heavy:
		if pose.phase == 1:
			return Frame.HEAVY_LOAD
		if pose.phase == 2:
			return Frame.HEAVY_HIT if pose.progress >= actor.weapon_controller.heavy_contact_progress else Frame.HEAVY_LOAD
		return Frame.HEAVY_HIT if pose.progress < 0.65 else Frame.IDLE
	if pose.phase == 1:
		return Frame.LIGHT_LOAD
	if pose.phase == 2:
		var contact := actor.weapon_controller.light_contact_progress if actor.weapon_controller else 0.5
		return Frame.LIGHT_HIT if pose.progress >= contact else Frame.LIGHT_LOAD
	return Frame.LIGHT_FINISH if pose.progress < 0.65 else Frame.IDLE

func _draw() -> void:
	draw_set_transform(Vector2(0, 1), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 9.0, Color(0.015, 0.02, 0.035, 0.65))
	draw_set_transform(Vector2.ZERO)
	if actor.health.dead:
		return
	if actor.team == 0:
		draw_arc(Vector2.ZERO, 8.0, 0.2, PI - 0.2, 10, Color(0.6, 0.8, 0.77, 0.35))
	if actor.team == 1 and actor.health.current < actor.health.maximum:
		draw_rect(Rect2(-10, -40, 20, 2), Color("332736"))
		draw_rect(Rect2(-10, -40, 20 * actor.health.current / actor.health.maximum, 2), Color("e99784"))
	if actor.stagger_left > 0.0:
		for i in range(3):
			var point := Vector2(cos(Time.get_ticks_msec() * 0.012 + i * TAU / 3.0) * 8.0, -37.0)
			draw_rect(Rect2(point, Vector2(2, 1)), Color("f2cb80"))

