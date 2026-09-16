class_name HitboxComponent
extends Node2D

signal connected(hit: DamageData, target: HurtboxComponent)
var team: int = 0
var hit: DamageData
var reach: float = 26.0
var half_angle: float = 1.0
var active: bool = false
var already_hit: Array[int] = []
var debug_visible: bool = false
var query_shape := CircleShape2D.new()

func begin(attack: DamageData, distance: float, spread: float) -> void:
	hit = attack
	reach = distance
	half_angle = spread
	already_hit.clear()
	active = true

func end() -> void:
	active = false
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if active:
		sample()
	if debug_visible:
		queue_redraw()

func sample() -> void:
	query_shape.radius = reach
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = query_shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 4
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for result in get_world_2d().direct_space_state.intersect_shape(query, 32):
		var target := result.collider as HurtboxComponent
		if target == null or target.team == team or already_hit.has(target.get_instance_id()):
			continue
		var offset := target.global_position - global_position
		if offset.length() > 5.0 and absf(hit.direction.angle_to(offset)) > half_angle:
			continue
		var ray := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		if target.receive(hit):
			already_hit.append(target.get_instance_id())
			connected.emit(hit, target)

func _draw() -> void:
	if debug_visible and active:
		draw_arc(Vector2.ZERO, reach, hit.direction.angle() - half_angle, hit.direction.angle() + half_angle, 20, Color(0.3, 1.0, 0.4, 0.8))
