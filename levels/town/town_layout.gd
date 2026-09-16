class_name TownLayout
extends RefCounted

const SIZE := Vector2(768, 480)
const BUILDINGS: Array[Dictionary] = [
	{"id": "shop", "name": "CORNER SUPPLY", "rect": Rect2(64, 64, 176, 144), "door": Vector2(152, 218), "color": Color("81bba0")},
	{"id": "hospital", "name": "MERCY HOSPITAL", "rect": Rect2(296, 64, 176, 144), "door": Vector2(384, 218), "color": Color("a8cbd6")},
	{"id": "bar", "name": "THE LAST LIGHT", "rect": Rect2(528, 64, 176, 144), "door": Vector2(616, 218), "color": Color("d7a385")}
]
const PROPS: Array[Rect2] = [Rect2(72, 386, 64, 20), Rect2(206, 386, 64, 20), Rect2(348, 398, 72, 24), Rect2(544, 398, 40, 24), Rect2(664, 374, 48, 24)]
const THUG_SPAWNS: Array[Vector2] = [Vector2(204, 264), Vector2(477, 281), Vector2(592, 355), Vector2(310, 365)]
const ROOM_ORIGINS := {"shop": Vector2(1200, 0), "hospital": Vector2(1600, 0), "bar": Vector2(2000, 0)}

static func door_for(id: String) -> Vector2:
	for building in BUILDINGS:
		if building.id == id:
			return building.door
	return Vector2(384, 254)

static func room_obstacles(id: String) -> Array[Rect2]:
	var result: Array[Rect2] = [Rect2(96, 70, 128, 24)]
	if id == "shop":
		result.append_array([Rect2(28, 77, 40, 68), Rect2(252, 77, 40, 68)])
	elif id == "hospital":
		result.append_array([Rect2(28, 80, 40, 54), Rect2(252, 80, 40, 54)])
	else:
		result.append_array([Rect2(34, 123, 34, 22), Rect2(252, 123, 34, 22)])
	return result

static func wall(parent: Node2D, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 0
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collider.shape = shape
	body.add_child(collider)
	parent.add_child(body)
