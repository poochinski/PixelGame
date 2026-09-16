class_name CombatPlayer
extends CombatActor

signal dodge_started
@export var dodge_duration: float = 0.22
@export var dodge_invulnerability: float = 0.16
@export var dodge_cooldown: float = 0.65
@export var dodge_speed: float = 220.0
var dodge_left: float = 0.0
var cooldown_left: float = 0.0
var dodge_direction := Vector2.RIGHT
var trail_left: float = 0.0
var controls_enabled: bool = true
var inventory: PlayerInventory

func _ready() -> void:
	super._ready()
	inventory = PlayerInventory.new()
	add_child(inventory)
	add_to_group("player")
	weapon_controller = MeleeController.new()
	add_child(weapon_controller)

func _physics_process(delta: float) -> void:
	tick_reaction(delta)
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if health.dead:
		velocity = knockback
		move_and_slide()
		return
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down") if controls_enabled else Vector2.ZERO
	if controls_enabled:
		var aim := get_global_mouse_position() - global_position
		if aim.length_squared() > 1.0:
			facing = aim.normalized()
		if Input.is_action_just_pressed("dodge"):
			try_dodge(movement)
	if dodge_left > 0.0:
		dodge_left = maxf(0.0, dodge_left - delta)
		velocity = dodge_direction * dodge_speed
		trail_left -= delta
		if trail_left <= 0.0:
			CombatFX.ghost(global_position, visual.texture, visual.sprite.flip_h, visual.sprite.scale, visual.sprite.position)
			trail_left = 0.035
	else:
		var movement_scale := weapon_controller.movement_multiplier()
		velocity = movement * move_speed * movement_scale if stagger_left <= 0.0 else Vector2.ZERO
		velocity += knockback
		if controls_enabled:
			if Input.is_action_just_pressed("primary_attack"):
				weapon_controller.request()
			if Input.is_action_just_pressed("secondary_attack"):
				weapon_controller.request(true)
	move_and_slide()

func try_dodge(movement: Vector2) -> bool:
	if health.dead or cooldown_left > 0.0 or stagger_left > 0.0:
		return false
	weapon_controller.cancel()
	dodge_direction = movement.normalized() if movement.length_squared() > 0.01 else facing
	dodge_left = dodge_duration
	cooldown_left = dodge_cooldown
	trail_left = 0.0
	knockback = Vector2.ZERO
	health.protect(dodge_invulnerability)
	CombatFX.shake(0.6)
	CombatFX.sound("dodge")
	dodge_started.emit()
	return true

func is_dodging() -> bool:
	return dodge_left > 0.0

func respawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	knockback = Vector2.ZERO
	stagger_left = 0.0
	dodge_left = 0.0
	cooldown_left = 0.0
	flash_left = 0.0
	collision_layer = 2
	collision_mask = 3
	hurtbox.monitorable = true
	health.restore()
	health.protect(1.0)
	weapon_controller.cancel()
