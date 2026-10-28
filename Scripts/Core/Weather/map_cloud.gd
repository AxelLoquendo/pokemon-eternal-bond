extends Node2D
## Puerto del CloudsManager de PokeDot-Engine.
## Autoload: MapCloud
## Las nubes viven en coordenadas de MUNDO (no siguen la cámara).
## Nunca aparecen dentro de la vista del jugador y no se superponen entre sí.

var lista_nubes: Array[Texture2D] = [
	preload("res://Graficos/Weather/clouds.png"),
]

## clouds.png (512x512) trae 3 nubes sueltas de 128x128 y el resto transparente.
## Se usa UNA por sprite para que su caja sea el tamaño real de la nube.
## Si cambias la textura, actualiza esta lista (vacía = usa la imagen completa).
var regiones_nubes: Array[Rect2] = [
	Rect2(32, 64, 128, 128),
	Rect2(352, 192, 128, 128),
	Rect2(192, 352, 128, 128),
]

@export var velocidad_min: float = 1.5
@export var velocidad_max: float = 4.0
@export var tiempo_creacion: float = 1.8
@export var color_base_nubes: Color = Color(1, 1, 1, 0.27)
@export var maximo_nubes_activas: int = 20
@export var nubes_iniciales: int = 8
## Hueco mínimo entre nubes (basta con cumplirlo en X o en Y).
@export var separacion_minima_x: float = 60.0
@export var separacion_minima_y: float = 40.0
## Una nube solo nace/se reubica a más de esta distancia de la vista.
@export var margen_visible: float = 32.0
## Hasta dónde se extiende el "cielo" activo alrededor de la vista.
@export var margen_activa: float = 300.0
@export var duracion_transicion: float = 0.8

var _desea_nubes: bool = true
var intensidad: float = 1.0
var _fade_tween: Tween
var temporizador_nubes: Timer
var camara_actual: Camera2D

var _contenedor: Node2D
var _iniciales_creadas: bool = false
var _acum_convoy: float = 0.0


func _ready() -> void:
	randomize()
	z_index = 50
	z_as_relative = false
	modulate.a = intensidad

	# Contenedor normal: se mueve con el mundo, NO con la cámara.
	_contenedor = Node2D.new()
	_contenedor.name = "Nubes"
	add_child(_contenedor)

	temporizador_nubes = Timer.new()
	temporizador_nubes.wait_time = tiempo_creacion
	temporizador_nubes.timeout.connect(crear_nube)
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


## Rectángulo que ve la cámara, en coordenadas de MUNDO.
func _rect_mundo() -> Rect2:
	if camara_actual == null or not is_instance_valid(camara_actual):
		camara_actual = get_viewport().get_camera_2d()
	if camara_actual == null:
		return Rect2()
	var tam: Vector2 = get_viewport().get_visible_rect().size / camara_actual.zoom
	var centro: Vector2 = camara_actual.get_screen_center_position()
	return Rect2(centro - tam * 0.5, tam)


func _tam_nube(nube: Sprite2D) -> Vector2:
	if nube.region_enabled:
		return nube.region_rect.size * nube.scale
	if nube.texture:
		return nube.texture.get_size() * nube.scale
	return Vector2.ZERO


## Caja real de la nube (el sprite usa centered = false: position = esquina).
func _caja(nube: Sprite2D) -> Rect2:
	return Rect2(nube.position, _tam_nube(nube))


## ¿La caja queda más cerca de otra nube que la separación mínima?
func _hay_choque(caja: Rect2, ignorar: Sprite2D = null) -> bool:
	var sep := Vector2(separacion_minima_x, separacion_minima_y)
	var caja_ext := Rect2(caja.position - sep, caja.size + sep * 2.0)
	for hijo: Node in _contenedor.get_children():
		var otra: Sprite2D = hijo as Sprite2D
		if otra == null or otra == ignorar:
			continue
		if caja_ext.intersects(_caja(otra)):
			return true
	return false


## Busca un sitio libre dentro del anillo activo y FUERA de la vista. Devuelve Vector2 o null.
func _buscar_posicion(tam: Vector2, rect: Rect2, ignorar: Sprite2D = null) -> Variant:
	var campo: Rect2 = rect.grow(margen_activa)
	var prohibido: Rect2 = rect.grow(margen_visible)
	var libre: Vector2 = campo.size - tam
	if libre.x <= 0.0 or libre.y <= 0.0:
		return null
	for _i in 30:
		var pos: Vector2 = campo.position + Vector2(randf() * libre.x, randf() * libre.y)
		var caja := Rect2(pos, tam)
		if prohibido.intersects(caja):
			continue
		if _hay_choque(caja, ignorar):
			continue
		return pos
	return null


func crear_nube() -> bool:
	if not _desea_nubes or lista_nubes.is_empty():
		return false
	if _contenedor.get_child_count() >= maximo_nubes_activas:
		return false
	var rect: Rect2 = _rect_mundo()
	if rect.size == Vector2.ZERO:
		return false

	var nube := Sprite2D.new()
	nube.texture = lista_nubes[randi() % lista_nubes.size()]
	nube.centered = false
	if not regiones_nubes.is_empty():
		nube.region_enabled = true
		nube.region_rect = regiones_nubes[randi() % regiones_nubes.size()]
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

	var pos: Variant = _buscar_posicion(_tam_nube(nube), rect)
	if not (pos is Vector2):
		nube.free()  # no hay sitio libre ahora mismo
		return false
	nube.position = pos
	nube.set_meta("velocidad", -randf_range(velocidad_min, velocidad_max))
	_contenedor.add_child(nube)
	return true


func crear_nubes_iniciales() -> void:
	for _i in nubes_iniciales:
		crear_nube()


## Mueve una nube a otro sitio libre del anillo (no se borra ni se vuelve a instanciar).
func _reubicar(nube: Sprite2D, rect: Rect2) -> void:
	var pos: Variant = _buscar_posicion(_tam_nube(nube), rect, nube)
	if pos is Vector2:
		nube.position = pos
		nube.set_meta("velocidad", -randf_range(velocidad_min, velocidad_max))


func _process(delta: float) -> void:
	var rect: Rect2 = _rect_mundo()
	if rect.size == Vector2.ZERO:
		return

	# Primer relleno: una sola vez, cuando ya hay cámara (siempre fuera de la vista).
	if not _iniciales_creadas and _desea_nubes:
		_iniciales_creadas = true
		crear_nubes_iniciales()

	var campo: Rect2 = rect.grow(margen_activa)
	var intento_reubicar: bool = false  # máximo 1 reubicación por frame
	for hijo: Node in _contenedor.get_children():
		var nube: Sprite2D = hijo as Sprite2D
		if nube == null:
			continue
		nube.position.x += float(nube.get_meta("velocidad", -2.5)) * delta

		# Salió del anillo (el jugador se alejó o hubo warp): reubicar.
		# En interiores no se toca nada: al salir las nubes siguen donde estaban.
		if _desea_nubes and not intento_reubicar and not campo.intersects(_caja(nube)):
			intento_reubicar = true
			_reubicar(nube, rect)

	_acum_convoy += delta
	if _acum_convoy >= 0.25:
		_acum_convoy = 0.0
		_evitar_alcance()


## Todas van hacia la izquierda con velocidades distintas: una rápida podría alcanzar
## a una lenta y juntarse. Si la de atrás se acerca demasiado, iguala la velocidad
## de la de adelante y la separación se mantiene.
func _evitar_alcance() -> void:
	var nubes: Array[Sprite2D] = []
	for hijo: Node in _contenedor.get_children():
		if hijo is Sprite2D:
			nubes.append(hijo as Sprite2D)

	var sep := Vector2(separacion_minima_x, separacion_minima_y)
	for i in nubes.size():
		for j in range(i + 1, nubes.size()):
			var a: Sprite2D = nubes[i]
			var b: Sprite2D = nubes[j]
			var ca: Rect2 = _caja(a)
			var ext := Rect2(ca.position - sep, ca.size + sep * 2.0)
			if not ext.intersects(_caja(b)):
				continue
			var delante: Sprite2D = a if a.position.x < b.position.x else b
			var detras: Sprite2D = b if delante == a else a
			var v_del: float = float(delante.get_meta("velocidad", -2.5))
			var v_det: float = float(detras.get_meta("velocidad", -2.5))
			if v_det < v_del:  # la de atrás es más rápida (más negativa)
				detras.set_meta("velocidad", v_del)


func activar() -> void:
	if temporizador_nubes:
		temporizador_nubes.paused = false
	_fade_a(1.0)


func desactivar() -> void:
	if temporizador_nubes:
		temporizador_nubes.paused = true
	# No borra nubes: solo fade (como en PokeDot-Engine)
	_fade_a(0.0)


func _fade_a(objetivo: float) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_method(_set_intensidad_visual, intensidad, objetivo, duracion_transicion)


func _set_intensidad_visual(v: float) -> void:
	intensidad = v
	modulate.a = intensidad
