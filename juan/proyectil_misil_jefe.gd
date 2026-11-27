extends Area2D

enum Tipo { TELEDIRIGIDO, BOMBARDEO }

const GIRO_MAXIMO := 2.2
const VIDA_TELEDIRIGIDO := 4.5
const TIEMPO_VUELO_BOMBARDEO := 3.2
const LADOS_AVISO := 36

var _objetivo: Node2D
var _tipo := Tipo.TELEDIRIGIDO
var _direccion := Vector2.RIGHT
var _destino := Vector2.ZERO
var _velocidad := 500.0
var _dano := 14.0
var _radio_explosion := 170.0
var _duracion_aviso := 0.9
var _edad := 0.0
var _aviso_restante := 0.0
var _detonando := false
var _aviso: Node2D

@onready var _cuerpo: Polygon2D = $Cuerpo


func _ready() -> void:
	body_entered.connect(_al_impactar)


func configurar(
	objetivo: Node2D,
	tipo: int,
	velocidad: float,
	dano: float,
	radio_explosion: float,
	duracion_aviso: float
) -> void:
	_objetivo = objetivo
	_tipo = tipo
	_velocidad = velocidad
	_dano = dano
	_radio_explosion = radio_explosion
	_duracion_aviso = duracion_aviso
	if is_instance_valid(_objetivo):
		_destino = _objetivo.global_position
		_direccion = (_destino - global_position).normalized()
	rotation = _direccion.angle() + PI / 2.0
	if _tipo == Tipo.BOMBARDEO:
		collision_mask = 0
		_cuerpo.color = Color(1.0, 0.12, 0.04)
	else:
		_cuerpo.color = Color(1.0, 0.48, 0.08)


func _physics_process(delta: float) -> void:
	_edad += delta
	if _detonando:
		_aviso_restante -= delta
		if is_instance_valid(_aviso):
			var avance := 1.0 - clampf(_aviso_restante / _duracion_aviso, 0.0, 1.0)
			_aviso.scale = Vector2.ONE * lerpf(0.7, 1.0, avance)
		if _aviso_restante <= 0.0:
			_detonar()
		return

	if _tipo == Tipo.TELEDIRIGIDO:
		_seguir_objetivo(delta)
		global_position += _direccion * _velocidad * delta
		if _edad >= VIDA_TELEDIRIGIDO:
			queue_free()
		return

	var hacia_destino := _destino - global_position
	if hacia_destino.length() <= _velocidad * delta or _edad >= TIEMPO_VUELO_BOMBARDEO:
		global_position = _destino
		_iniciar_aviso()
	else:
		_direccion = hacia_destino.normalized()
		global_position += _direccion * _velocidad * delta
	rotation = _direccion.angle() + PI / 2.0


func _seguir_objetivo(delta: float) -> void:
	if not is_instance_valid(_objetivo):
		return
	var direccion_deseada := (_objetivo.global_position - global_position).normalized()
	var diferencia_angular := _direccion.angle_to(direccion_deseada)
	var giro := clampf(diferencia_angular, -GIRO_MAXIMO * delta, GIRO_MAXIMO * delta)
	_direccion = _direccion.rotated(giro).normalized()
	rotation = _direccion.angle() + PI / 2.0


func _iniciar_aviso() -> void:
	_detonando = true
	_aviso_restante = _duracion_aviso
	_aviso = Node2D.new()
	_aviso.name = "AvisoImpactoMisil"
	_aviso.z_index = 5
	var relleno := Polygon2D.new()
	relleno.polygon = _circulo(_radio_explosion, LADOS_AVISO)
	relleno.color = Color(1.0, 0.08, 0.02, 0.32)
	_aviso.add_child(relleno)
	var borde := Line2D.new()
	borde.points = _circulo(_radio_explosion, LADOS_AVISO, true)
	borde.width = 7.0
	borde.default_color = Color(1.0, 0.36, 0.06, 0.95)
	_aviso.add_child(borde)
	add_child(_aviso)
	_cuerpo.hide()


func _detonar() -> void:
	if is_instance_valid(_objetivo):
		if _objetivo.global_position.distance_to(global_position) <= _radio_explosion:
			_objetivo.call("recibir_dano", _dano)
	queue_free()


func _al_impactar(cuerpo: Node2D) -> void:
	if _tipo != Tipo.TELEDIRIGIDO or not cuerpo.is_in_group("jugador"):
		return
	if cuerpo.has_method("recibir_dano"):
		cuerpo.call("recibir_dano", _dano)
	queue_free()


func _circulo(radio: float, lados: int, cerrar: bool = false) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for indice in lados:
		var angulo := TAU * float(indice) / float(lados)
		puntos.append(Vector2(cos(angulo), sin(angulo)) * radio)
	if cerrar:
		puntos.append(puntos[0])
	return puntos
