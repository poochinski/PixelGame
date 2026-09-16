class_name StreetThug
extends CombatActor

signal money_dropped(amount: int, at: Vector2)

enum State { IDLE, CHASE, WINDUP, STRIKE, RECOVER, STAGGER, DEAD, CIRCLE, COMMIT }
@export var detection_range: float = 240.0
@export var attack_range: float = 25.0
@export var windup_time: float = 0.54
@export var attack_damage: float = 14.0
@export var circle_distance: float = 43.0
@export var circle_duration: float = 0.6
@export var recovery_time: float = 0.85
@export var starts_hostile: bool = true
var hostile: bool = true
var state: State = State.IDLE
var state_time: float = 0.0
var attack_direction := Vector2.LEFT
var target: CombatPlayer
var hitbox: HitboxComponent
var navigation: AStarGrid2D
var path: PackedVector2Array
var repath_left: float = 0.0
var orbit_sign: float = 1.0
var enabled: bool = true

func _ready() -> void:
	hostile = starts_hostile
	team = 1
	super._ready()
	add_to_group("enemies")
	hitbox = HitboxComponent.new()
	hitbox.team = team
	add_child(hitbox)

func _physics_process(delta: float) -> void:
	tick_reaction(delta)
	state_time -= delta
	if health.dead:
		state = State.DEAD
		hitbox.end()
		velocity = knockback
	elif not enabled:
		velocity = Vector2.ZERO
	elif stagger_left > 0.0:
		state = State.STAGGER
		hitbox.end()
		velocity = knockback
	elif not is_instance_valid(target) or target.health.dead:
		state = State.IDLE
		hitbox.end()
		velocity = knockback
	elif not hostile:
		state = State.IDLE
		hitbox.end()
		velocity = knockback
	else:
		var offset := target.global_position - global_position
		var distance := offset.length()
		match state:
			State.IDLE, State.CHASE:
				facing = offset.normalized()
				if distance > detection_range:
					state = State.IDLE
					velocity = knockback
				elif distance <= attack_range and _clear_sight():
					_begin_attack()
				elif distance < 55.0 and _clear_sight():
					state = State.CIRCLE
					state_time = circle_duration
					velocity = Vector2.ZERO
				else:
					state = State.CHASE
					velocity = _chase(delta) * move_speed + knockback
			State.CIRCLE:
				facing = offset.normalized()
				var tangent := facing.orthogonal() * orbit_sign
				var spacing := clampf((distance - circle_distance) / 12.0, -1.0, 1.0)
				velocity = (tangent * 0.65 + facing * spacing).limit_length() * move_speed * 0.6
				if distance <= attack_range and _clear_sight():
					_begin_attack()
				elif state_time <= 0.0:
					state = State.COMMIT
					state_time = 1.2
			State.COMMIT:
				facing = offset.normalized()
				velocity = _chase(delta) * move_speed * 1.12 + knockback
				if distance <= attack_range and _clear_sight():
					_begin_attack()
				elif state_time <= 0.0 or distance > 90.0:
					state = State.CHASE
			State.WINDUP:
				velocity = knockback
				# Readable commitment: no homing during the last 0.28s or the strike.
				if state_time > 0.28:
					attack_direction = offset.normalized()
				facing = attack_direction
				if state_time <= 0.0:
					state = State.STRIKE
					state_time = 0.16
					CombatFX.sound("swing", 0.7)
			State.STRIKE:
				velocity = attack_direction * 40.0
				if state_time <= 0.08 and not hitbox.active:
					var hit := DamageData.new()
					hit.amount = attack_damage
					hit.knockback = 100.0
					hit.stagger = 0.23
					hit.source = self
					hit.direction = attack_direction
					hitbox.begin(hit, 28.0, 0.8)
				if state_time <= 0.0:
					hitbox.end()
					state = State.RECOVER
					state_time = recovery_time
					orbit_sign *= -1.0
			State.RECOVER:
				# A long planted follow-through, then a short backstep to reset spacing.
				velocity = knockback
				if state_time < 0.25:
					velocity += (-attack_direction + attack_direction.orthogonal() * orbit_sign * 0.3) * 24.0
				if state_time <= 0.0:
					state = State.CIRCLE
					state_time = circle_duration * 0.7
			State.STAGGER:
				state = State.RECOVER
				state_time = 0.3
				velocity = knockback
	move_and_slide()
	queue_redraw()

func _begin_attack() -> void:
	state = State.WINDUP
	state_time = windup_time
	attack_direction = facing
	velocity = Vector2.ZERO

func _clear_sight() -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _walkable_near(point: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := INF
	for y in range(point.y - 4, point.y + 5):
		for x in range(point.x - 4, point.x + 5):
			var candidate := Vector2i(x, y)
			if not navigation.is_in_boundsv(candidate) or navigation.is_point_solid(candidate):
				continue
			var distance := Vector2(candidate - point).length_squared()
			if distance < best_distance:
				best = candidate
				best_distance = distance
	return best

func _chase(delta: float) -> Vector2:
	if _clear_sight():
		return (target.global_position - global_position).normalized()
	if navigation == null:
		return Vector2.ZERO
	repath_left -= delta
	if repath_left <= 0.0:
		repath_left = 0.25
		var start := _walkable_near(Vector2i(global_position / 8.0))
		var finish := _walkable_near(Vector2i(target.global_position / 8.0))
		if start.x >= 0 and finish.x >= 0:
			path = navigation.get_point_path(start, finish)
	while path.size() > 0 and global_position.distance_to(path[0]) < 5.0:
		path.remove_at(0)
	return (path[0] - global_position).normalized() if path.size() > 0 else Vector2.ZERO

func _on_damaged(hit: DamageData) -> void:
	if is_instance_valid(hit.source) and hit.source is CombatPlayer:
		hostile = true
		target = hit.source
	super._on_damaged(hit)
	if hitbox:
		hitbox.end()
	state = State.STAGGER

func _on_died() -> void:
	super._on_died()
	money_dropped.emit(randi_range(1, 10), global_position)

func _draw() -> void:
	if health == null or health.dead:
		return
	if state == State.WINDUP or state == State.STRIKE:
		var locked := state == State.STRIKE or state_time <= 0.28
		var color := Color("f6c487") if not locked else Color("f17d68")
		var angle := attack_direction.angle()
		draw_arc(Vector2.ZERO, 28.0, angle - 0.8, angle + 0.8, 12, Color(color, 0.8), 1.0)
		draw_line(Vector2.from_angle(angle - 0.8) * 20, Vector2.from_angle(angle - 0.8) * 28, color)
		draw_line(Vector2.from_angle(angle + 0.8) * 20, Vector2.from_angle(angle + 0.8) * 28, color)
		draw_rect(Rect2(-1, -40, 2, 5), color)
		draw_rect(Rect2(-1, -33, 2, 1), color)

func presentation_pose() -> CombatPose:
	var guard_pose := CombatPose.guard(facing)
	var phase_id := 0
	var progress := 0.0
	if state == State.WINDUP:
		phase_id = 1
		progress = 1.0 - state_time / windup_time
	elif state == State.STRIKE:
		phase_id = 2
		progress = 1.0 - state_time / 0.16
	elif state == State.RECOVER:
		phase_id = 3
		progress = 1.0 - state_time / recovery_time
	if phase_id == 0:
		return guard_pose
	return CombatPose.swing(attack_direction, phase_id, progress, 1, false, guard_pose.bat_angle, guard_pose.hand_offset)

