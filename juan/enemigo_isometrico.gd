extends CharacterBody2D

const GOBLIN = preload("res://assets/personajes_nuevos/enemigo_goblin.png")
const OGRO = preload("res://assets/personajes_nuevos/jefe_ogro.png")
const MISIL_JEFE = preload("res://juan/proyectil_misil_jefe.tscn")
const TAMANO_CELDA := 256
const INTERVALO_MISIL_JEFE := 3.4
const ALCANCE_MISIL_JEFE := 1900.0
const VELOCIDAD_MISIL_GUIADO := 500.0
const VELOCIDAD_MISIL_ASALTO := 330.0
const DANO_MISIL_GUIADO := 14.0
const DANO_MISIL_ASALTO := 23.0
const RADIO_MISIL_ASALTO := 170.0
const AVISO_MISIL_ASALTO := 0.9

@export var velocidad := 75.0
@export var integridad := 3

var _jugador: CharacterBody2D
var _director: DirectorCampana
var _tiempo_ataque := 0.0
var _puntos := 100
var _es_jefe := false
var _derrotado := false
var _sprite: Sprite2D
var _tiempo_animacion := 0.0
var _cuadro := 0
var _fila := 0
var _cuenta_para_oleada := true
var _enfriamiento_misil_jefe := 1.5
var _misiles_jefe_disparados := 0


func configurar(
	rapidez: float,
	puntos: int,
	jefe: bool,
	cuenta_para_oleada: bool = true,
	vida_jefe: int = 18,
	intervalo_disparo_rango: float = 1.8,
	velocidad_proyectil_rango: float = 420.0,
	dano_proyectil_rango: float = 8.0
) -> void:
	velocidad = rapidez * 42.0
	_puntos = puntos
	_es_jefe = jefe
	_cuenta_para_oleada = cuenta_para_oleada
	if jefe:
		_enfriamiento_misil_jefe = 1.5
		_misiles_jefe_disparados = 0
	if jefe:
		integridad = vida_jefe
	if has_method("_configurar_intervalo_disparo"):
		call("_configurar_intervalo_disparo", intervalo_disparo_rango)
	if has_method("_configurar_disparo_rango"):
		call(
			"_configurar_disparo_rango",
			intervalo_disparo_rango,
			velocidad_proyectil_rango,
			dano_proyectil_rango
		)


func _ready() -> void:
	add_to_group("enemigos")
	collision_layer = 4
	collision_mask = 1
	var base := CollisionPolygon2D.new()
	base.polygon = PackedVector2Array([Vector2(-24, 0), Vector2(0, -13), Vector2(24, 0), Vector2(0, 13)])
	add_child(base)
	_crear_apariencia()
	_jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody2D
	_director = get_tree().get_first_node_in_group("director_campana") as DirectorCampana


func _physics_process(delta: float) -> void:
	_tiempo_ataque = maxf(_tiempo_ataque - delta, 0.0)
	_enfriamiento_misil_jefe = maxf(_enfriamiento_misil_jefe - delta, 0.0)
	if not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody2D
		return
	var distancia := global_position.distance_to(_jugador.global_position)
	if distancia > 34.0:
		var direccion := (_jugador.global_position - global_position).normalized()
		velocity = direccion * velocidad
		# El spritesheet empieza mirando en sentido opuesto al ángulo de movimiento.
		_fila = (roundi(direccion.angle() / (TAU / 8.0)) + 12) % 8
		_tiempo_animacion += delta
		if _tiempo_animacion >= 0.14:
			_tiempo_animacion = 0.0
			_cuadro = (_cuadro + 1) % 4
		move_and_slide()
		_sprite.region_rect = Rect2(_cuadro * TAMANO_CELDA, _fila * TAMANO_CELDA, TAMANO_CELDA, TAMANO_CELDA)
	elif _tiempo_ataque <= 0.0:
		velocity = Vector2.ZERO
		_jugador.call("recibir_dano", 16.0 if _es_jefe else 10.0)
		_tiempo_ataque = 0.9

	if _es_jefe and _enfriamiento_misil_jefe <= 0.0 and distancia <= ALCANCE_MISIL_JEFE:
		_disparar_misil_jefe()


func _disparar_misil_jefe() -> void:
	var contenedor := get_tree().get_first_node_in_group("contenedor_entidades")
	if contenedor == null or not is_instance_valid(_jugador):
		return

	var misil := MISIL_JEFE.instantiate() as Area2D
	contenedor.add_child(misil)
	misil.global_position = global_position + Vector2(0.0, -34.0)
	var tipo := 0 if _misiles_jefe_disparados % 2 == 0 else 1
	misil.call(
		"configurar",
		_jugador,
		tipo,
		VELOCIDAD_MISIL_GUIADO if tipo == 0 else VELOCIDAD_MISIL_ASALTO,
		DANO_MISIL_GUIADO if tipo == 0 else DANO_MISIL_ASALTO,
		RADIO_MISIL_ASALTO,
		AVISO_MISIL_ASALTO
	)
	_misiles_jefe_disparados += 1
	_enfriamiento_misil_jefe = INTERVALO_MISIL_JEFE


func recibir_dano(cantidad: int = 1) -> void:
	if _derrotado:
		return
	integridad -= cantidad
	modulate = Color(1.0, 0.45, 0.3)
	var destello := create_tween()
	destello.tween_property(self, "modulate", Color.WHITE, 0.12)
	if integridad <= 0:
		_derrotado = true
		if is_instance_valid(_director) and _cuenta_para_oleada:
			_director.registrar_enemigo_derrotado(_puntos, _es_jefe)
		queue_free()


func _crear_apariencia() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "Personaje"
	_sprite.texture = OGRO if _es_jefe else GOBLIN
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(0, 0, TAMANO_CELDA, TAMANO_CELDA)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.position.y = -60
	_sprite.scale = Vector2(0.82, 0.82)
	add_child(_sprite)
