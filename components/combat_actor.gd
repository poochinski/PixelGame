class_name CombatActor
extends CharacterBody2D

@export var max_health: float = 100.0
@export var move_speed: float = 88.0
@export var team: int = 0
var health: HealthComponent
var hurtbox: HurtboxComponent
var facing := Vector2.RIGHT
var knockback := Vector2.ZERO
var stagger_left: float = 0.0
var flash_left: float = 0.0
var visual: ActorVisual
var weapon_controller: MeleeController

func _ready() -> void:
	collision_layer = 2
	collision_mask = 3
	var collider := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	collider.shape = circle
	add_child(collider)
	health = HealthComponent.new()
	health.maximum = max_health
	add_child(health)
	hurtbox = HurtboxComponent.new()
	hurtbox.actor = self
	hurtbox.health = health
	hurtbox.team = team
	add_child(hurtbox)
	visual = ActorVisual.new()
	visual.actor = self
	add_child(visual)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)

func tick_reaction(delta: float) -> void:
	stagger_left = maxf(0.0, stagger_left - delta)
	flash_left = maxf(0.0, flash_left - delta)
	knockback = knockback.move_toward(Vector2.ZERO, 600.0 * delta)

func _on_damaged(hit: DamageData) -> void:
	knockback = hit.direction * hit.knockback
	stagger_left = maxf(stagger_left, hit.stagger)
	flash_left = 0.105
	if weapon_controller:
		weapon_controller.cancel()
	CombatFX.impact(global_position + Vector2(0, -18), hit, team == 0)

func _on_died() -> void:
	collision_layer = 0
	collision_mask = 1
	hurtbox.set_deferred("monitorable", false)
	if weapon_controller:
		weapon_controller.cancel()

func is_dodging() -> bool:
	return false

func presentation_pose() -> CombatPose:
	if weapon_controller:
		return weapon_controller.presentation_pose()
	return CombatPose.guard(facing)

func lunge(impulse: Vector2) -> void:
	knockback += impulse
