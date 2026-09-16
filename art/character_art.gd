class_name CharacterArt
extends RefCounted

static var cache: Dictionary = {}

# Original hand-authored pixel masks, split at the neck and waist for animation.
# O outline, M shadow, J jacket, L seam highlight, C lapel, S shirt, B belt.
const FRONT: Array[String] = [
"....OOOOOOOO....",
"..OOLLLLLLJJOO..",
".OLLLCSSCLJJJJO.",
".OLLCCSSCCJJJJO.",
".OLJOCSSCOJJJMO.",
".OLJOSSSSOJJJMO.",
"..OJOOSSOOJJMO..",
"..OJJOSSOJJJMO..",
"..OJLOSSLJJJMO..",
"..OJJOSSOJJJMO..",
"..OJJOOSOJJJMO..",
"...OJJOJJJJMO...",
"...OBBBBBBBBO...",
"...OOMMOOOMOO..."]
const BACK: Array[String] = [
"....OOOOOOOO....",
"..OOLLLLLLJJOO..",
".OLLLLLLLLLJJJO.",
".OLJJJJJJJJJJMO.",
".OLJMMMMMMJJJMO.",
".OLJMLLLLMJJJMO.",
"..OJMJJJJMJJMO..",
"..OJMJJJJMJJMO..",
"..OJMMMMMMJJMO..",
"..OJLJJJJLJJMO..",
"..OJJJJJJJJJMO..",
"...OJJJJJJJMO...",
"...OBBBBBBBBO...",
"...OOMMOOOMOO..."]
const SIDE: Array[String] = [
".....OOOOOO.....",
"....OLLJJJOO....",
"...OLLLJJJMOO...",
"...OLLJJJCCSO...",
"...OLJJJMOCSO...",
"...OLJJJMOSSO...",
"....OJJJMOSSO...",
"....OLJJMOSSO...",
"....OJJJMOSSO...",
"....OJJJMOSSO...",
"....OJJJMOSSO...",
"....OJJJMOOO....",
"....OBBBBBBO....",
"....OMMOOOMO...."]

static func torso(team: int, direction: int) -> Texture2D:
	var key := "torso_%d_%d" % [team, direction]
	if cache.has(key):
		return cache[key]
	var colors := {
		"O": Color("171a26"), "M": Color("293c52") if team == 0 else Color("633840"),
		"J": Color("49687e") if team == 0 else Color("985146"),
		"L": Color("899fa5") if team == 0 else Color("ce8b6b"),
		"C": Color("c4c4ad") if team == 0 else Color("bf9779"),
		"S": Color("a8ad9e") if team == 0 else Color("2e2930"),
		"B": Color("423b40")}
	var pixels := Image.create(16, 14, false, Image.FORMAT_RGBA8)
	pixels.fill(Color.TRANSPARENT)
	var rows: Array[String] = BACK if direction == 2 else SIDE if direction == 1 else FRONT
	for y in range(rows.size()):
		for x in range(rows[y].length()):
			var symbol := rows[y][x]
			if colors.has(symbol):
				pixels.set_pixel(x, y, colors[symbol])
	# Worn shoulder patch, zip, brass buckle and asymmetric seam.
	if team == 0 and direction != 2:
		pixels.fill_rect(Rect2i(5, 4, 2, 1), Color("b78c68"))
		pixels.set_pixel(8 if direction == 0 else 10, 12, Color("cfb792"))
	if team == 1 and direction == 2:
		pixels.fill_rect(Rect2i(6, 5, 4, 3), Color("ccab84"))
		pixels.fill_rect(Rect2i(7, 6, 2, 1), Color("744742"))
	cache[key] = ImageTexture.create_from_image(pixels)
	return cache[key]

static func head(team: int, direction: int) -> Texture2D:
	var key := "head_%d_%d" % [team, direction]
	if cache.has(key):
		return cache[key]
	var pixels := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	pixels.fill(Color.TRANSPARENT)
	var ink := Color("1b1c29")
	var skin := Color("e4b990") if team == 0 else Color("d6a17d")
	var shade := Color("a06e5f")
	pixels.fill_rect(Rect2i(3, 1, 6, 9), ink)
	pixels.fill_rect(Rect2i(2, 3, 8, 5), ink)
	pixels.fill_rect(Rect2i(3, 3, 6, 5), skin)
	pixels.fill_rect(Rect2i(4, 8, 4, 2), shade)
	pixels.fill_rect(Rect2i(5, 10, 3, 2), shade)
	pixels.fill_rect(Rect2i(3, 2, 6, 2), Color("3b3039") if team == 0 else Color("74605f"))
	if team == 0:
		pixels.fill_rect(Rect2i(3, 1, 5, 2), Color("34303a"))
		pixels.fill_rect(Rect2i(4, 1, 3, 1), Color("726471"))
		pixels.fill_rect(Rect2i(2, 3, 2, 3), Color("34303a"))
	if direction == 2:
		pixels.fill_rect(Rect2i(3, 4, 6, 4), Color("37313d") if team == 0 else Color("957267"))
		pixels.fill_rect(Rect2i(4, 8, 4, 1), Color("70606a"))
	elif direction == 1:
		pixels.fill_rect(Rect2i(9, 5, 2, 2), skin)
		pixels.set_pixel(8, 4, ink)
		pixels.set_pixel(4, 5, shade)
		pixels.fill_rect(Rect2i(7, 8, 2, 1), ink)
	else:
		pixels.set_pixel(4, 5, ink)
		pixels.set_pixel(7, 5, ink)
		pixels.set_pixel(6, 6, Color("f3d2aa"))
		pixels.fill_rect(Rect2i(5, 8, 3, 1), Color("74545a"))
	if team == 1 and direction != 2:
		pixels.set_pixel(8, 6, Color("a76159"))
	cache[key] = ImageTexture.create_from_image(pixels)
	return cache[key]

# Neutral full-body silhouette for the existing inexpensive dodge ghost.
static func ghost(team: int, direction: int) -> Texture2D:
	var key := "ghost_%d_%d" % [team, direction]
	if cache.has(key):
		return cache[key]
	var pixels := Image.create(24, 36, false, Image.FORMAT_RGBA8)
	pixels.fill(Color.TRANSPARENT)
	pixels.fill_rect(Rect2i(7, 25, 4, 9), Color("465468"))
	pixels.fill_rect(Rect2i(14, 25, 4, 9), Color("303d52"))
	pixels.fill_rect(Rect2i(6, 32, 5, 3), Color("17202b"))
	pixels.fill_rect(Rect2i(14, 32, 6, 3), Color("17202b"))
	pixels.blend_rect(torso(team, direction).get_image(), Rect2i(0, 0, 16, 14), Vector2i(4, 12))
	pixels.blend_rect(head(team, direction).get_image(), Rect2i(0, 0, 12, 12), Vector2i(6, 2))
	cache[key] = ImageTexture.create_from_image(pixels)
	return cache[key]

