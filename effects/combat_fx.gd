extends Node

const Burst = preload("res://effects/impact_burst.gd")
const Number = preload("res://effects/damage_number.gd")
var camera: Camera2D
var hitstop_until: int = 0
var hitstop_enabled: bool = true
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var voice_index: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for kind in ["swing", "impact", "heavy", "dodge", "death", "cash"]:
		sounds[kind] = _synthesize(kind)
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -14.0
		add_child(voice)
		voices.append(voice)

func _process(_delta: float) -> void:
	if hitstop_until > 0 and Time.get_ticks_msec() >= hitstop_until:
		Engine.time_scale = 1.0
		hitstop_until = 0

func impact(at: Vector2, hit: DamageData, player_damage: bool) -> void:
	if get_tree().current_scene == null:
		return
	var burst := Burst.new()
	burst.position = at
	burst.z_index = 20
	burst.setup(hit.direction, hit.heavy)
	get_tree().current_scene.add_child(burst)
	var number := Number.new()
	number.position = at + Vector2(randf_range(-5, 5), -25)
	number.amount = roundi(hit.amount)
	number.emphasized = hit.heavy or hit.critical
	number.player_damage = player_damage
	get_tree().current_scene.add_child(number)
	shake(2.0 if hit.heavy else 1.0)
	sound("heavy" if hit.heavy else "impact")
	if hitstop_enabled:
		hitstop_until = maxi(hitstop_until, Time.get_ticks_msec() + (65 if hit.heavy else 32))
		Engine.time_scale = 0.08

func shake(strength: float) -> void:
	if is_instance_valid(camera):
		camera.trauma = maxf(camera.trauma, strength)

func ghost(at: Vector2, texture: Texture2D, flipped: bool, draw_scale: Vector2 = Vector2.ONE, draw_offset: Vector2 = Vector2(0, -16)) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.flip_h = flipped
	sprite.position = at + draw_offset
	sprite.scale = draw_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate = Color(0.45, 0.85, 0.8, 0.45)
	get_tree().current_scene.add_child(sprite)
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.18)
	tween.tween_callback(sprite.queue_free)

func sound(kind: String, pitch: float = 1.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var voice := voices[voice_index % voices.size()]
	voice_index += 1
	voice.stream = sounds.get(kind, sounds["impact"])
	voice.pitch_scale = pitch * randf_range(0.94, 1.06)
	voice.play()

func _synthesize(kind: String) -> AudioStreamWAV:
	var sample_rate := 22050
	var seconds := 0.22 if kind == "heavy" or kind == "death" else 0.13
	var count := int(sample_rate * seconds)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = kind.hash()
	var filtered_noise := 0.0
	for i in range(count):
		var t := float(i) / sample_rate
		var envelope := pow(1.0 - float(i) / count, 2.5)
		filtered_noise = lerpf(filtered_noise, rng.randf_range(-1, 1), 0.4)
		var frequency := 65.0 if kind == "heavy" else 110.0
		var sample := (sin(TAU * frequency * t * (1.0 - t * 2.0)) * 0.7 + filtered_noise * 0.6) * envelope
		if kind == "swing" or kind == "dodge":
			sample = filtered_noise * sin(PI * float(i) / count) * envelope
		elif kind == "cash":
			sample = (sin(TAU * 880.0 * t) + sin(TAU * 1320.0 * t) * 0.35) * envelope * 0.35
		data.encode_s16(i * 2, int(clampf(sample, -1, 1) * 24000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _exit_tree() -> void:
	Engine.time_scale = 1.0
	for voice in voices:
		voice.stop()
		voice.stream = null
	sounds.clear()
