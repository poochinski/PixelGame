class_name MeleeController
extends Node2D

signal attack_started(index: int, heavy: bool)
enum Phase { IDLE, WINDUP, ACTIVE, RECOVERY }
@export var weapon: MeleeWeaponData = preload("res://weapons/baseball_bat.tres")
@export var combo_window: float = 0.55
@export_range(0.0, 1.0) var light_contact_progress: float = 0.5
@export_range(0.0, 1.0) var heavy_contact_progress: float = 0.78
var actor: CombatActor
var hitbox: HitboxComponent
var phase: Phase = Phase.IDLE
var timer: float = 0.0
var duration: float = 0.0
var combo: int = 0
var combo_remaining: float = 0.0
var heavy: bool = false
var attack_direction := Vector2.RIGHT
var buffered: int = 0
var buffer_remaining: float = 0.0
var swing_sign: float = 1.0
var enabled: bool = true
var windup_from: float = 0.0
var windup_hand := Vector2.ZERO
var pending_hit: DamageData
var busy: bool:
	get: return phase != Phase.IDLE

func _ready() -> void:
	actor = get_parent() as CombatActor
	hitbox = HitboxComponent.new()
	hitbox.team = actor.team
	add_child(hitbox)

func request(is_heavy: bool = false) -> void:
	if not enabled or actor.health.dead or actor.stagger_left > 0.0 or actor.is_dodging():
		return
	if busy:
		buffered = 2 if is_heavy else 1
		buffer_remaining = 0.3
	else:
		start_attack(is_heavy)

func start_attack(is_heavy: bool) -> void:
	var previous_pose := presentation_pose()
	windup_from = previous_pose.bat_angle
	windup_hand = previous_pose.hand_offset
	heavy = is_heavy
	combo = 0 if heavy else (combo % 3 + 1 if combo_remaining > 0.0 else 1)
	attack_direction = actor.facing
	swing_sign = -1.0 if combo == 2 else 1.0
	phase = Phase.WINDUP
	duration = (0.32 if heavy else 0.11 if combo < 3 else 0.15) / weapon.attack_speed
	timer = duration
	buffered = 0
	attack_started.emit(combo, heavy)

func _physics_process(delta: float) -> void:
	combo_remaining = maxf(0.0, combo_remaining - delta)
	buffer_remaining = maxf(0.0, buffer_remaining - delta)
	if buffer_remaining <= 0.0:
		buffered = 0
	if not busy:
		queue_redraw()
		return
	timer -= delta
	if timer <= 0.0:
		match phase:
			Phase.WINDUP:
				phase = Phase.ACTIVE
				duration = 0.14 if heavy else 0.12
				timer = duration
				var hit := DamageData.new()
				hit.amount = weapon.base_damage * (2.4 if heavy else 1.6 if combo == 3 else 1.0)
				hit.knockback = weapon.knockback * (2.5 if heavy else 1.8 if combo == 3 else 1.0)
				hit.stagger = 0.65 if heavy else 0.42 if combo == 3 else weapon.stagger
				hit.source = actor
				hit.direction = attack_direction
				hit.heavy = heavy or combo == 3
				pending_hit = hit
				CombatFX.sound("swing", 0.8 if heavy else 1.0 + combo * 0.08)
			Phase.ACTIVE:
				hitbox.end()
				phase = Phase.RECOVERY
				duration = (0.34 if heavy else 0.15 if combo < 3 else 0.25) / weapon.attack_speed
				timer = duration
			Phase.RECOVERY:
				phase = Phase.IDLE
				combo_remaining = 0.0 if heavy else combo_window
				if buffered > 0:
					request(buffered == 2)
	# Overhead attacks connect late, after the raised hands and barrel descend.
	var contact_progress := heavy_contact_progress if heavy else light_contact_progress
	if phase == Phase.ACTIVE and pending_hit != null and timer <= duration * (1.0 - contact_progress):
		actor.lunge(attack_direction * (70.0 if heavy else 45.0))
		hitbox.begin(pending_hit, weapon.reach + (4.0 if heavy else 0.0), 1.15)
		pending_hit = null
	queue_redraw()

func cancel() -> void:
	phase = Phase.IDLE
	buffered = 0
	combo = 0
	combo_remaining = 0.0
	pending_hit = null
	hitbox.end()
	queue_redraw()

func weapon_angle() -> float:
	return presentation_pose().bat_angle

func presentation_pose() -> CombatPose:
	if not busy:
		return CombatPose.guard(actor.facing)
	var progress := clampf(1.0 - timer / maxf(duration, 0.001), 0.0, 1.0)
	return CombatPose.swing(attack_direction, phase, progress, combo, heavy, windup_from, windup_hand)

func movement_multiplier() -> float:
	if phase == Phase.WINDUP or phase == Phase.ACTIVE:
		return 0.0
	return 0.5 if phase == Phase.RECOVERY else 1.0

func _draw() -> void:
	if not is_instance_valid(actor) or actor.health.dead:
		return
	if phase == Phase.ACTIVE and hitbox.active:
		var color := Color("f9d285") if heavy or combo == 3 else Color("d5e0cf")
		var angle := attack_direction.angle()
		draw_arc(Vector2(0, -12), weapon.reach - 3.0, angle - 0.35, angle + 0.35, 8, Color(color, 0.45), 1.0)
