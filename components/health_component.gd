class_name HealthComponent
extends Node

signal changed(current: float, maximum: float)
signal damaged(hit: DamageData)
signal died

@export var maximum: float = 100.0
var current: float = 100.0
var invulnerability: float = 0.0
var dead: bool:
	get: return current <= 0.0

func _ready() -> void:
	current = maximum

func _physics_process(delta: float) -> void:
	invulnerability = maxf(0.0, invulnerability - delta)

func receive(hit: DamageData) -> bool:
	if dead or invulnerability > 0.0 or hit.amount <= 0.0:
		return false
	current = maxf(0.0, current - hit.amount)
	changed.emit(current, maximum)
	damaged.emit(hit)
	if dead:
		died.emit()
	return true

func heal(amount: float) -> void:
	if dead:
		return
	current = minf(maximum, current + maxf(0.0, amount))
	changed.emit(current, maximum)

func protect(seconds: float) -> void:
	invulnerability = maxf(invulnerability, seconds)

func restore() -> void:
	current = maximum
	invulnerability = 0.0
	changed.emit(current, maximum)
