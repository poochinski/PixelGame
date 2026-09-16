class_name Footwork
extends RefCounted

var contacts: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var feet: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var lift: Array[float] = [0.0, 0.0]
var previous_phase: Array[float] = [0.0, 0.5]
var previous_position := Vector2.ZERO
var travel: float = 0.0
var initialized: bool = false
var was_attacking: bool = false
var moving: bool = false
var movement_direction := Vector2.DOWN
var bob: float = 0.0

func update(at: Vector2, aim: Vector2, pose: CombatPose, delta: float) -> void:
	var displacement := at - previous_position
	if not initialized or displacement.length() > 32.0:
		_reset(at, aim)
		displacement = Vector2.ZERO
	var distance := displacement.length()
	var planted := pose.active and (pose.phase != 3 or pose.progress < 0.25)
	moving = distance > 0.15 and not planted
	if planted and not was_attacking:
		var across := aim.orthogonal()
		contacts[0] = at - across * 4.5 - aim * 3.0
		contacts[1] = at + across * 4.5 + aim * 3.0
	if planted:
		# Feet keep their world positions as the hips turn and the body lunges.
		for i in range(2):
			feet[i] = (contacts[i] - at).limit_length(13.0)
			lift[i] = 0.0
		bob = 0.0
	elif moving:
		movement_direction = displacement.normalized()
		travel += distance
		var across := aim.orthogonal()
		for i in range(2):
			var cycle := fposmod(travel / 24.0 + i * 0.5, 1.0)
			var side := -1.0 if i == 0 else 1.0
			var landing := at + across * side * 3.7 + movement_direction * 6.6
			if cycle < 0.55:
				if previous_phase[i] >= 0.55 or was_attacking:
					contacts[i] = landing
				feet[i] = (contacts[i] - at).limit_length(14.0)
				lift[i] = 0.0
			else:
				var progress := (cycle - 0.55) / 0.45
				var foot := contacts[i].lerp(landing, smoothstep(0.0, 1.0, progress))
				feet[i] = (foot - at).limit_length(14.0)
				lift[i] = sin(progress * PI) * 3.0
			previous_phase[i] = cycle
		bob = -absf(sin(travel / 24.0 * TAU)) * 0.9
	else:
		var across := aim.orthogonal()
		for i in range(2):
			var side := -1.0 if i == 0 else 1.0
			var rest := across * side * 4.0 + aim * side * 1.5
			feet[i] = feet[i].lerp(rest, minf(delta * 14.0, 1.0))
			contacts[i] = at + feet[i]
			lift[i] = 0.0
		bob = 0.0
	was_attacking = planted
	previous_position = at

func _reset(at: Vector2, aim: Vector2) -> void:
	initialized = true
	travel = 0.0
	for i in range(2):
		var side := -1.0 if i == 0 else 1.0
		feet[i] = aim.orthogonal() * side * 4.0
		contacts[i] = at + feet[i]
		lift[i] = 0.0
	previous_position = at
	previous_phase = [0.0, 0.5]

