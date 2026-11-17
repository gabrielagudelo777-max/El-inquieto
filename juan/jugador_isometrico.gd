extends CharacterBody2D

signal integridad_cambiada(actual: float)

const PROYECTIL = preload("res://juan/proyectil_isometrico.tscn")
const PERSONAJE = preload("res://assets/personajes_nuevos/jugador_armadura.png")
const TAMANO_CELDA := 256

@export var velocidad := 280.0
@export var velocidad_correr := 390.0
@export var velocidad_esquive := 720.0

var integridad := 100.0
var _director: DirectorCampana
var _sprite: Sprite2D
var _direccion_esquive := Vector2.ZERO
var _enfriamiento_esquive := 0.0
var _tiempo_esquive := 0.0
var _enfriamiento_disparo := 0.0
var _tiempo_ataque := 0.0
var _tiempo_dano := 0.0
var _tiempo_animacion := 0.0
var _cuadro := 0
var _fila := 2


func _ready() -> void:
	add_to_group("jugador")
	collision_layer = 1
	collision_mask = 1

	var base := CollisionPolygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-24, 0),
		Vector2(0, -13),
		Vector2(24, 0),
		Vector2(0, 13)
	])
	add_child(base)

	_sprite = Sprite2D.new()
	_sprite.name = "Personaje"
	_sprite.texture = PERSONAJE
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(0, 0, TAMANO_CELDA, TAMANO_CELDA)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.position.y = -48
	_sprite.scale = Vector2(0.82, 0.82)
	add_child(_sprite)

	call_deferred("_conectar_director")


func _physics_process(delta: float) -> void:
	if _director != null and _director.estado != DirectorCampana.Estado.COMBATE:
		velocity = Vector2.ZERO
		return

	_enfriamiento_esquive = maxf(_enfriamiento_esquive - delta, 0.0)
	_enfriamiento_disparo = maxf(_enfriamiento_disparo - delta, 0.0)
	_tiempo_esquive = maxf(_tiempo_esquive - delta, 0.0)
	_tiempo_ataque = maxf(_tiempo_ataque - delta, 0.0)
	_tiempo_dano = maxf(_tiempo_dano - delta, 0.0)

	_tiempo_animacion += delta
	var corriendo := Input.is_action_pressed("correr")
	var intervalo_animacion := 0.09 if corriendo else 0.12
	if _tiempo_animacion >= intervalo_animacion:
		_tiempo_animacion = 0.0
		_cuadro = (_cuadro + 1) % 4

	var teclas := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)
	var movimiento := Vector2(
		teclas.x - teclas.y,
		(teclas.x + teclas.y) * 0.5
	).normalized()

	if movimiento.length_squared() > 0.0:
		_fila = _fila_para_direccion(movimiento)

	if Input.is_action_just_pressed("dash") and _enfriamiento_esquive <= 0.0:
		_direccion_esquive = (
			movimiento if movimiento.length_squared() > 0.0 else Vector2.RIGHT
		)
		_tiempo_esquive = 0.18
		_enfriamiento_esquive = 0.75

	if _tiempo_esquive > 0.0:
		velocity = _direccion_esquive * velocidad_esquive
	else:
		var velocidad_actual := velocidad_correr if corriendo else velocidad
		velocity = movimiento * velocidad_actual

	move_and_slide()

	position.x = clampf(position.x, -840.0, 840.0)
	position.y = clampf(position.y, -390.0, 390.0)

	var fuera_del_diamante := absf(position.x) / 840.0 + absf(position.y) / 390.0
	if fuera_del_diamante > 1.0:
		position /= fuera_del_diamante

	_actualizar_sprite(movimiento)

	if Input.is_action_pressed("disparar") and _enfriamiento_disparo <= 0.0:
		_disparar()
		_enfriamiento_disparo = 0.28


func recibir_dano(cantidad: float) -> void:
	integridad = maxf(integridad - cantidad, 0.0)
	integridad_cambiada.emit(integridad)
	_tiempo_dano = 0.2

	if integridad <= 0.0:
		if _director == null:
			_conectar_director()

		if _director != null:
			_director.recibir_impacto()

			if _director.vidas > 0:
				integridad = 100.0
				integridad_cambiada.emit(integridad)


func _disparar() -> void:
	var objetivo := _buscar_objetivo()
	if objetivo == null:
		return

	var direccion := (objetivo.global_position - global_position).normalized()
	var proyectil := PROYECTIL.instantiate() as Area2D
	var contenedor := get_tree().get_first_node_in_group("contenedor_entidades")

	if contenedor == null:
		return

	contenedor.add_child(proyectil)
	proyectil.global_position = global_position + direccion * 24.0 + Vector2(0, -20)
	proyectil.call("configurar", direccion)

	_tiempo_ataque = 0.24
	_fila = _fila_para_direccion(direccion)


func _fila_para_direccion(direccion: Vector2) -> int:
	if direccion.is_zero_approx():
		return _fila

	var pasos := roundi(direccion.angle() / (TAU / 8.0))
	return posmod(pasos + 4, 8)


func _actualizar_sprite(movimiento: Vector2) -> void:
	var cuadro := 0

	if _tiempo_dano > 0.0:
		cuadro = 6
	elif _tiempo_ataque > 0.0:
		cuadro = 4 + (_cuadro % 2)
	elif _tiempo_esquive > 0.0:
		cuadro = 3
	elif movimiento.length_squared() > 0.0:
		cuadro = _cuadro

	_sprite.region_rect = Rect2(
		cuadro * TAMANO_CELDA,
		_fila * TAMANO_CELDA,
		TAMANO_CELDA,
		TAMANO_CELDA
	)
	_sprite.modulate = (
		Color(1.0, 0.48, 0.42)
		if _tiempo_dano > 0.0
		else Color.WHITE
	)


func _buscar_objetivo() -> Node2D:
	var cercano: Node2D
	var menor_distancia := INF

	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		if not is_instance_valid(enemigo):
			continue

		var distancia := global_position.distance_squared_to(enemigo.global_position)
		if distancia < menor_distancia:
			menor_distancia = distancia
			cercano = enemigo

	return cercano


func _conectar_director() -> void:
	_director = get_tree().get_first_node_in_group("director_campana") as DirectorCampana
