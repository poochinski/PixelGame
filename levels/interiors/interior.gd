extends Node2D

@export_enum("shop", "hospital", "bar") var kind: String = "shop"

func _ready() -> void:
	var art := preload("res://levels/town/town_art.gd").new()
	art.interior = kind
	add_child(art)
	for rect in [Rect2(0, 0, 320, 68), Rect2(0, 216, 320, 16), Rect2(0, 0, 16, 224), Rect2(304, 0, 16, 224)]:
		TownLayout.wall(self, rect)
	for rect in TownLayout.room_obstacles(kind):
		TownLayout.wall(self, rect)
