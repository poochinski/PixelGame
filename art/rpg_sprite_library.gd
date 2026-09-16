class_name RPGSpriteLibrary
extends RefCounted

# Source sheets are original generated art. Cells are rendered with nearest
# filtering; no body parts or weapons are rotated independently at runtime.
const SOURCES: Array[String] = [
	"res://art/sprites/survivor_rpg_v1.png",
	"res://art/sprites/thug_rpg_v1.png"
]
const COLUMNS: int = 8
const ROWS: int = 4
const DISPLAY_CELL := Vector2(36, 48)
static var sheets: Dictionary = {}
static var frames: Dictionary = {}
static var dimensions: Dictionary = {}
static var metadata: Dictionary = {}

static func sheet(team: int) -> Texture2D:
	if not sheets.has(team):
		var loaded := load(SOURCES[clampi(team, 0, 1)]) as Texture2D
		assert(loaded != null, "Missing RPG character sprite atlas")
		sheets[team] = loaded
		dimensions[team] = Vector2(loaded.get_width() / 8.0, loaded.get_height() / 4.0)
		metadata[team] = JSON.parse_string(FileAccess.get_file_as_string(SOURCES[clampi(team, 0, 1)].get_basename() + ".json"))
		assert(metadata[team].frames.size() == 32, "Incomplete RPG sprite metadata")
	return sheets[team]

static func frame(team: int, direction: int, column: int) -> Texture2D:
	var atlas := sheet(team)
	var key := Vector3i(team, direction, column)
	if not frames.has(key):
		var data: Dictionary = frame_data(team, direction, column)
		var bounds: Array = data.region
		var region := AtlasTexture.new()
		region.atlas = atlas
		region.region = Rect2(bounds[0], bounds[1], bounds[2], bounds[3])
		region.filter_clip = true
		frames[key] = region
	return frames[key]

static func render_scale(team: int) -> Vector2:
	sheet(team)
	return DISPLAY_CELL / Vector2(dimensions[team])

static func frame_data(team: int, direction: int, column: int) -> Dictionary:
	# The south follow-through occludes the weapon; hold the readable contact pose.
	if direction == 0 and column == 5:
		column = 4
	return metadata[team].frames[direction * COLUMNS + column]

static func sprite_offset(team: int, direction: int, column: int) -> Vector2:
	var data := frame_data(team, direction, column)
	var bounds: Array = data.region
	var anchor: Array = data.anchor
	return (Vector2(bounds[0], bounds[1]) + Vector2(bounds[2], bounds[3]) * 0.5 - Vector2(anchor[0], anchor[1])) * render_scale(team)

