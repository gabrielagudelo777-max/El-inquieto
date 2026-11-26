extends CharacterBody2D

signal integridad_cambiada(actual: float)
signal murio

const PROYECTIL = preload("res://juan/proyectil_isometrico.tscn")
const TAMANO_CELDA := 256
const CUADROS_CAMINATA := 4
const INTERVALO_ANIMACION := 0.14

@export var velocidad := 280.0
@export var velocidad_correr := 390.0
@export var velocidad_esquive := 720.0
@export var integridad_maxima := 100.0
@export var duracion_invulnerabilidad := 0.75
@export var duracion_esquive := 0.18
@export var enfriamiento_esquive := 0.75
@export var intervalo_disparo := 0.28
@export var dano_proyectil := 1
@export var punto_reaparicion := Vector2(0.0, 210.0)

var integridad := 100.0
var _director: DirectorCampana
@onready var _sprite: Sprite2D = $SpriteCaballero
var _direccion_esquive := Vector2.ZERO
var _direccion_mirada := Vector2.RIGHT
var _enfriamiento_esquive := 0.0
var _tiempo_esquive := 0.0
var _enfriamiento_disparo := 0.0
var _tiempo_dano := 0.0
var _tiempo_invulnerabilidad := 0.0
var _tiempo_animacion := 0.0
var _cuadro := 0
var _fila := 0
var _muerto := false
var _velocidad_base := 0.0
var _velocidad_correr_base := 0.0
var _intervalo_disparo_base := 0.28
var _dano_proyectil_base := 1
var _mejora_activa: MejoraConfig


func _ready() -> void:
	_velocidad_base = velocidad
	_velocidad_correr_base = velocidad_correr
	_intervalo_disparo_base = intervalo_disparo
	_dano_proyectil_base = dano_proyectil
	add_to_group("jugador")
	collision_layer = 1
	collision_mask = 1
	integridad = integridad_maxima

	call_deferred("_conectar_director")


func _physics_process(delta: float) -> void:
	if _muerto:
		velocity = Vector2.ZERO
		return

	if _director == null:
		_conectar_director()

	if _director != null and _director.estado != DirectorCampana.Estado.COMBATE:
		velocity = Vector2.ZERO
		return

	_enfriamiento_esquive = maxf(_enfriamiento_esquive - delta, 0.0)
	_enfriamiento_disparo = maxf(_enfriamiento_disparo - delta, 0.0)
	_tiempo_esquive = maxf(_tiempo_esquive - delta, 0.0)
	_tiempo_dano = maxf(_tiempo_dano - delta, 0.0)
	_tiempo_invulnerabilidad = maxf(_tiempo_invulnerabilidad - delta, 0.0)
	var corriendo := Input.is_action_pressed("correr")

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
		_direccion_mirada = movimiento

	if (
		Input.is_action_just_pressed("dash")
		and _enfriamiento_esquive <= 0.0
	):
		_direccion_esquive = (
			movimiento
			if movimiento.length_squared() > 0.0
			else _direccion_mirada
		)
		_direccion_mirada = _direccion_esquive
		_tiempo_esquive = duracion_esquive
		_enfriamiento_esquive = enfriamiento_esquive
		_tiempo_invulnerabilidad = maxf(
			_tiempo_invulnerabilidad,
			duracion_esquive
		)

	if _tiempo_esquive > 0.0:
		velocity = _direccion_esquive * velocidad_esquive
	else:
		var velocidad_actual := velocidad_correr if corriendo else velocidad
		velocity = movimiento * velocidad_actual

	move_and_slide()

	position.x = clampf(position.x, -1792.0, 1792.0)
	position.y = clampf(position.y, -896.0, 896.0)

	var fuera_del_diamante := absf(position.x) / 1792.0 + absf(position.y) / 896.0
	if fuera_del_diamante > 1.0:
		position /= fuera_del_diamante

	var direccion_animacion := velocity.normalized() if velocity.length_squared() > 0.0 else Vector2.ZERO
	_actualizar_sprite(direccion_animacion, delta)

	if Input.is_action_pressed("disparar") and _enfriamiento_disparo <= 0.0:
		_disparar()
		_enfriamiento_disparo = intervalo_disparo


func aplicar_mejora_temporal(mejora: MejoraConfig) -> bool:
	if mejora == null:
		push_error("JugadorIsometrico: no se puede aplicar una mejora vacía.")
		return false

	limpiar_mejora_temporal()
	_mejora_activa = mejora

	match mejora.tipo:
		MejoraConfig.Tipo.DANO_PROYECTIL:
			dano_proyectil = _dano_proyectil_base + maxi(roundi(mejora.valor), 0)
		MejoraConfig.Tipo.CADENCIA_DISPARO:
			var reduccion := clampf(mejora.valor, 0.0, 0.9)
			intervalo_disparo = maxf(_intervalo_disparo_base * (1.0 - reduccion), 0.05)
		MejoraConfig.Tipo.VELOCIDAD:
			var aumento := clampf(mejora.valor, 0.0, 1.0)
			velocidad = _velocidad_base * (1.0 + aumento)
			velocidad_correr = _velocidad_correr_base * (1.0 + aumento)

	_enfriamiento_disparo = minf(_enfriamiento_disparo, intervalo_disparo)
	return true


func limpiar_mejora_temporal() -> void:
	velocidad = _velocidad_base
	velocidad_correr = _velocidad_correr_base
	intervalo_disparo = _intervalo_disparo_base
	dano_proyectil = _dano_proyectil_base
	_enfriamiento_disparo = intervalo_disparo
	_mejora_activa = null


func recibir_dano(cantidad: float) -> void:
	if cantidad <= 0.0 or _muerto:
		return

	if _director == null:
		_conectar_director()

	if _director == null or _director.estado != DirectorCampana.Estado.COMBATE:
		return

	if _tiempo_invulnerabilidad > 0.0:
		return

	integridad = maxf(integridad - cantidad, 0.0)
	_tiempo_dano = 0.58
	_tiempo_invulnerabilidad = duracion_invulnerabilidad
	integridad_cambiada.emit(integridad)

	if integridad <= 0.0:
		_muerto = true
		velocity = Vector2.ZERO
		murio.emit()


func reaparecer() -> void:
	if not _muerto:
		return

	if _director == null:
		_conectar_director()

	if _director == null or _director.estado != DirectorCampana.Estado.COMBATE:
		return

	position = punto_reaparicion
	velocity = Vector2.ZERO
	integridad = integridad_maxima
	_muerto = false
	_tiempo_esquive = 0.0
	_tiempo_dano = 0.0
	_tiempo_invulnerabilidad = duracion_invulnerabilidad
	_sprite.modulate = Color.WHITE
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
	proyectil.call("configurar", direccion, dano_proyectil)
	_direccion_mirada = direccion


func _actualizar_sprite(movimiento: Vector2, delta: float) -> void:
	# La hoja, igual que las de los enemigos, organiza las 8 direcciones
	# por filas y los 4 cuadros de caminar por columnas.
	if movimiento.length_squared() > 0.0:
		_direccion_mirada = movimiento.normalized()
		_fila = (roundi(_direccion_mirada.angle() / (TAU / 8.0)) + 12) % 8
		_tiempo_animacion += delta
		var intervalo := INTERVALO_ANIMACION
		if _tiempo_esquive > 0.0:
			intervalo = 0.07
		elif velocity.length() > velocidad:
			intervalo = 0.11
		if _tiempo_animacion >= intervalo:
			_tiempo_animacion = 0.0
			_cuadro = (_cuadro + 1) % CUADROS_CAMINATA
	else:
		_fila = (roundi(_direccion_mirada.angle() / (TAU / 8.0)) + 12) % 8
		_cuadro = 0
		_tiempo_animacion = 0.0

	_sprite.region_rect = Rect2(
		_cuadro * TAMANO_CELDA,
		_fila * TAMANO_CELDA,
		TAMANO_CELDA,
		TAMANO_CELDA
	)

	var opacidad := 1.0
	if _tiempo_invulnerabilidad > 0.0:
		var fase_parpadeo := int(_tiempo_invulnerabilidad / 0.08)
		if fase_parpadeo % 2 == 0:
			opacidad = 0.45

	var color := Color(1.0, 0.48, 0.42) if _tiempo_dano > 0.0 else Color.WHITE
	color.a = opacidad
	_sprite.modulate = color


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
