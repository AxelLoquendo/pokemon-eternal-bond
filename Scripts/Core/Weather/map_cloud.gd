extends Node2D
## Puerto del CloudsManager de PokeDot-Engine.
## Autoload: MapClouds

var lista_nubes: Array[Texture2D] = [
	preload("res://Graficos/Weather/clouds.png"),
]

@export var velocidad_min: float = 1.5
@export var velocidad_max: float = 4.0
@export var tiempo_creacion: float = 1.8
@export var alto_min: float = 40.0
@export var alto_max: float = 280.0
@export var color_base_nubes: Color = Color(1, 1, 1, 0.27)
@export var maximo_nubes_activas: int = 20
@export var separacion_minima_x: float = 60.0
@export var separacion_minima_y: float = 25.0
@export var margen_fuera: float = 50.0
@export var duracion_transicion: float = 0.8

var _desea_nubes: bool = true
var intensidad: float = 1.0
var _fade_tween: Tween
var temporizador_nubes: Timer
var camara_actual: Camera2D

## Ancla que NO sigue la cámara (Godot 4)
var _parallax: Parallax2D


func _ready() -> void:
	randomize()

	_parallax = Parallax2D.new()
	_parallax.name = "CloudParallax"
	_parallax.scroll_scale = Vector2.ZERO  # ← fijo a pantalla
	_parallax.z_index = 50
	_parallax.z_as_relative = false
	add_child(_parallax)

	camara_actual = get_viewport().get_camera_2d()
	modulate.a = intensidad

	temporizador_nubes = Timer.new()
	temporizador_nubes.wait_time = tiempo_creacion
	temporizador_nubes.timeout.connect(crear_nube_entrante)
	temporizador_nubes.autostart = true
	add_child(temporizador_nubes)


func set_outdoor(outdoor: bool) -> void:
	## API para GameSession (igual que indoor del mapa).
	if outdoor == _desea_nubes:
		return
	_desea_nubes = outdoor
	if _desea_nubes:
		activar()
	else:
		desactivar()


func hay_superposicion(nueva_x: float, nueva_y: float) -> bool:
	for hijo: Node in _parallax.get_children():
		if hijo is Sprite2D:
			var nube: Sprite2D = hijo as Sprite2D
			if nube.texture == null:
				continue
			var ancho: float = nube.texture.get_width() * nube.scale.x
			var alto: float = nube.texture.get_height() * nube.scale.y
			if (
				absf(nube.position.x - nueva_x) < maxf(separacion_minima_x, ancho * 0.5)
				and absf(nube.position.y - nueva_y) < maxf(separacion_minima_y, alto * 0.5)
			):
				return true
	return false


func crear_nube(pos_x: float, pos_y: float) -> void:
	if not _desea_nubes:
		return
	if _parallax.get_child_count() >= maximo_nubes_activas:
		return
	if hay_superposicion(pos_x, pos_y) or lista_nubes.is_empty():
		return

	var nube := Sprite2D.new()
	nube.texture = lista_nubes[randi() % lista_nubes.size()]
	nube.position = Vector2(pos_x, pos_y)
	var escala: float = randf_range(0.6, 1.0)
	nube.scale = Vector2.ONE * escala
	var brillo: float = randf_range(0.9, 1.05)
	var alpha: float = color_base_nubes.a * randf_range(0.7, 1.0)
	nube.modulate = Color(
		color_base_nubes.r * brillo,
		color_base_nubes.g * brillo,
		color_base_nubes.b * brillo,
		alpha
	)
	nube.set_meta("velocidad", -randf_range(velocidad_min, velocidad_max))
	_parallax.add_child(nube)


func crear_nube_entrante() -> void:
	if not _desea_nubes:
		return
	if camara_actual == null:
		camara_actual = get_viewport().get_camera_2d()
	if camara_actual == null:
		return

	var rect_camara: Rect2 = camara_actual.get_viewport_rect()
	var nueva_pos_x: float = rect_camara.end.x + margen_fuera
	for _intentos in 30:
		var nueva_pos_y: float = randf_range(alto_min, alto_max)
		if not hay_superposicion(nueva_pos_x, nueva_pos_y):
			crear_nube(nueva_pos_x, nueva_pos_y)
			return


func _process(delta: float) -> void:
	if camara_actual == null:
		camara_actual = get_viewport().get_camera_2d()

	var rect_camara: Rect2 = Rect2(Vector2.ZERO, Vector2(480, 320))
	if camara_actual:
		rect_camara = camara_actual.get_viewport_rect()

	for hijo: Node in _parallax.get_children():
		if hijo is Sprite2D:
			var nube: Sprite2D = hijo as Sprite2D
			var velocidad: float = float(nube.get_meta("velocidad", -2.5))
			nube.position.x += velocidad * delta
			if nube.texture:
				var ancho: float = nube.texture.get_width() * nube.scale.x
				if nube.position.x + ancho * 0.5 < rect_camara.position.x - margen_fuera:
					nube.queue_free()


func activar() -> void:
	if temporizador_nubes:
		temporizador_nubes.paused = false
	var cantidad: int = _parallax.get_child_count()
	if cantidad == 0:
		crear_nubes_iniciales()
	_fade_a(1.0)


func crear_nubes_iniciales() -> void:
	for _i in 5:
		crear_nube(randf_range(0.0, 480.0), randf_range(alto_min, alto_max))


func desactivar() -> void:
	if temporizador_nubes:
		temporizador_nubes.paused = true
	# No borra nubes: solo fade (como en PokeDot-Engine)
	_fade_a(0.0)


func _fade_a(objetivo: float) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "intensidad", objetivo, duracion_transicion)
	_fade_tween.set_parallel(false)
	# Actualiza alpha del contenedor mientras dura el tween
	_fade_tween.tween_method(_set_intensidad_visual, intensidad, objetivo, duracion_transicion)


func _set_intensidad_visual(v: float) -> void:
	intensidad = v
	modulate.a = intensidad
