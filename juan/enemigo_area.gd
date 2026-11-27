extends "res://juan/enemigo_isometrico.gd"
class_name EnemigoArea

const RADIO_ATAQUE := 150.0
const TIEMPO_AVISO := 0.9
const DISTANCIA_ATAQUE := 390.0
const ENFRIAMIENTO_ATAQUE := 4.5
const DANO_AREA := 18.0

var _enfriamiento_area := 2.0
var _aviso_restante := 0.0
var _centro_ataque := Vector2.ZERO
var _aviso: Node2D


func _ready() -> void:
	super._ready()
	if is_instance_valid(_sprite):
		_sprite.modulate = Color(1.0, 0.48, 0.22)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody2D
		return
	if _director != null and _director.estado != DirectorCampana.Estado.COMBATE:
		velocity = Vector2.ZERO
		return

	_enfriamiento_area = maxf(_enfriamiento_area - delta, 0.0)
	if _aviso_restante > 0.0:
		_aviso_restante -= delta
		velocity = Vector2.ZERO
		if is_instance_valid(_aviso):
			_aviso.scale = Vector2.ONE * (1.0 + (TIEMPO_AVISO - _aviso_restante) * 0.12)
		if _aviso_restante <= 0.0:
			_detonar_ataque()
		return

	var diferencia := _jugador.global_position - global_position
	var distancia := diferencia.length()
	var direccion := diferencia.normalized()
	if distancia > DISTANCIA_ATAQUE * 0.45:
		velocity = direccion * velocidad
		move_and_slide()
		_fila = (roundi(direccion.angle() / (TAU / 8.0)) + 12) % 8
		_tiempo_animacion += delta
		if _tiempo_animacion >= 0.14:
			_tiempo_animacion = 0.0
			_cuadro = (_cuadro + 1) % 4
		_sprite.region_rect = Rect2(_cuadro * TAMANO_CELDA, _fila * TAMANO_CELDA, TAMANO_CELDA, TAMANO_CELDA)
	else:
		velocity = Vector2.ZERO
		if distancia <= DISTANCIA_ATAQUE and _enfriamiento_area <= 0.0:
			_iniciar_ataque()


func _iniciar_ataque() -> void:
	_centro_ataque = _jugador.global_position
	_aviso = Node2D.new()
	_aviso.name = "AvisoAtaqueDeArea"
	_aviso.position = _centro_ataque
	_aviso.z_index = 5
	var relleno := Polygon2D.new()
	relleno.polygon = _circulo(RADIO_ATAQUE, 32)
	relleno.color = Color(1.0, 0.12, 0.04, 0.25)
	_aviso.add_child(relleno)
	var borde := Line2D.new()
	borde.points = _circulo(RADIO_ATAQUE, 32, true)
	borde.width = 5.0
	borde.default_color = Color(1.0, 0.28, 0.08, 0.9)
	_aviso.add_child(borde)
	var contenedor := get_tree().get_first_node_in_group("contenedor_entidades")
	if contenedor != null:
		contenedor.add_child(_aviso)
		_aviso_restante = TIEMPO_AVISO
	else:
		_aviso.queue_free()
		_enfriamiento_area = 1.0


func _detonar_ataque() -> void:
	if is_instance_valid(_aviso):
		_aviso.queue_free()
	if is_instance_valid(_jugador) and _jugador.global_position.distance_to(_centro_ataque) <= RADIO_ATAQUE:
		_jugador.call("recibir_dano", DANO_AREA)
	_enfriamiento_area = ENFRIAMIENTO_ATAQUE


func _circulo(radio: float, lados: int, cerrar: bool = false) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in lados:
		var angulo := TAU * float(i) / float(lados)
		puntos.append(Vector2(cos(angulo), sin(angulo)) * radio)
	if cerrar:
		puntos.append(puntos[0])
	return puntos
