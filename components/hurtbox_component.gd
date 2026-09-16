class_name HurtboxComponent
extends Area2D

var health: HealthComponent
var actor: Node2D
var team: int = 0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	shape.shape = circle
	add_child(shape)

func receive(hit: DamageData) -> bool:
	return health.receive(hit)
