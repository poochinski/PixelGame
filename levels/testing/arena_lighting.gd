extends Node2D

var neon: PointLight2D
var phase: float = 0.0

func _ready() -> void:
	var ambient := CanvasModulate.new()
	ambient.color = Color(0.62, 0.67, 0.79, 1.0)
	add_child(ambient)
	_add_lamp(Vector2(166, 154), Color("ffd1a0"), 1.05, 230.0)
	_add_lamp(Vector2(339, 171), Color("9bcbd4"), 0.95, 235.0)
	neon = _add_lamp(Vector2(240, 127), Color("e895aa"), 0.68, 150.0)

func _add_lamp(at: Vector2, color: Color, energy: float, diameter: float) -> PointLight2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.72), Color(1, 1, 1, 0.2), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var lamp := PointLight2D.new()
	lamp.position = at
	lamp.texture = texture
	lamp.texture_scale = diameter / 128.0
	lamp.color = color
	lamp.energy = energy
	lamp.shadow_enabled = true
	lamp.shadow_color = Color(0.04, 0.045, 0.08, 0.65)
	lamp.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	add_child(lamp)
	return lamp

func _process(delta: float) -> void:
	phase += delta
	# Subtle transformer variation, never a distracting full-screen flash.
	neon.energy = 0.68 + sin(phase * 7.0) * 0.015 + sin(phase * 19.0) * 0.009

