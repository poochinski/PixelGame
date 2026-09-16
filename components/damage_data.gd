class_name DamageData
extends RefCounted

enum Type { BLUNT, BLADE, BALLISTIC, FIRE, ELECTRIC, TOXIC, OCCULT }
var amount: float = 10.0
var damage_type: Type = Type.BLUNT
var knockback: float = 90.0
var stagger: float = 0.2
var critical: bool = false
var source: Node2D
var direction: Vector2 = Vector2.RIGHT
var heavy: bool = false
