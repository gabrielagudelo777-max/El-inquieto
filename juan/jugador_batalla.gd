extends CharacterBody3D

const PROYECTIL := preload("res://juan/proyectil_batalla.tscn")

@onready var _animacion: AnimationPlayer = find_child("AnimationPlayer", true, false) as AnimationPlayer

@export var velocidad_movimiento := 5.2
@export var velocidad_dash := 13.5
@export var limite_arena := 8.65

var integridad := 100.0
var _direccion_dash := Vector3.ZERO
var _tiempo_dash := 0.0
var _enfriamiento_disparo := 0.0
var _invulnerabilidad := 0.0
var _director: DirectorCampana
var _tiempo_dano := 0.0
var _tiempo_ataque := 0.0
var _animacion_actual := ""


func _ready() -> void:
	add_to_group("jugador")
	_configurar_animaciones()
	_reproducir_animacion("Idle")
	call_deferred("_conectar_director")


func _physics_process(delta: float) -> void:
	if _director != null and _director.estado != DirectorCampana.Estado.COMBATE:
		velocity = Vector3.ZERO
		return
	_enfriamiento_disparo = maxf(0.0, _enfriamiento_disparo - delta)
	_tiempo_dash = maxf(0.0, _tiempo_dash - delta)
	_invulnerabilidad = maxf(0.0, _invulnerabilidad - delta)
	_tiempo_dano = maxf(0.0, _tiempo_dano - delta)
	_tiempo_ataque = maxf(0.0, _tiempo_ataque - delta)
	var entrada := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direccion := Vector3(entrada.x, 0.0, entrada.y).normalized()
	if Input.is_action_just_pressed("dash") and direccion.length_squared() > 0.0 and _tiempo_dash <= 0.0:
		_direccion_dash = direccion
		_tiempo_dash = 0.18
	if _tiempo_dash > 0.0:
		velocity.x = _direccion_dash.x * velocidad_dash
		velocity.z = _direccion_dash.z * velocidad_dash
	else:
		velocity.x = direccion.x * velocidad_movimiento
		velocity.z = direccion.z * velocidad_movimiento
	move_and_slide()
	var posicion := global_position
	posicion.x = clampf(posicion.x, -limite_arena, limite_arena)
	posicion.z = clampf(posicion.z, -limite_arena, limite_arena)
	global_position = posicion
	_actualizar_animacion(direccion)
	if Input.is_action_pressed("disparar") and _enfriamiento_disparo <= 0.0:
		_disparar()
		_enfriamiento_disparo = 0.28


func recibir_dano(cantidad: float) -> void:
	if _invulnerabilidad > 0.0:
		return
	integridad = maxf(0.0, integridad - cantidad)
	_invulnerabilidad = 0.55
	_tiempo_dano = 0.58
	if integridad <= 0.0:
		if _director == null:
			_conectar_director()
		if _director != null:
			_director.recibir_impacto()
			if _director.vidas > 0:
				integridad = 100.0
		if integridad <= 0.0:
			_reproducir_animacion("Death")


func _conectar_director() -> void:
	_director = get_tree().get_first_node_in_group("director_campana") as DirectorCampana


func _disparar() -> void:
	var objetivo := _buscar_objetivo()
	var direccion := Vector3.FORWARD
	if objetivo:
		direccion = objetivo.global_position - global_position
		direccion.y = 0.0
		direccion = direccion.normalized()
		look_at(global_position + direccion, Vector3.UP)
	if direccion.length_squared() <= 0.0:
		return
	var proyectil := PROYECTIL.instantiate()
	get_tree().current_scene.add_child(proyectil)
	proyectil.global_position = global_position + Vector3.UP * 0.82 + direccion * 0.65
	proyectil.configurar_direccion(direccion)
	if _animacion == null or _animacion_actual != "Sword_Shield_Slash_Down" or not _animacion.is_playing():
		_tiempo_ataque = 1.33


func _actualizar_animacion(direccion: Vector3) -> void:
	if _tiempo_dano > 0.0:
		_reproducir_animacion("Take_Damage")
	elif _tiempo_ataque > 0.0:
		_reproducir_animacion("Sword_Shield_Slash_Down")
	elif _tiempo_dash > 0.0:
		_reproducir_animacion(_animacion_direccional(_direccion_dash, "Run_"))
	elif direccion.length_squared() > 0.0:
		var prefijo := "Run_" if Input.is_action_pressed("correr") else "Walk_"
		_reproducir_animacion(_animacion_direccional(direccion, prefijo))
	else:
		_reproducir_animacion("Idle")


func _animacion_direccional(direccion: Vector3, prefijo: String) -> String:
	var direccion_local := global_transform.basis.inverse() * direccion
	var angulo := atan2(direccion_local.x, -direccion_local.z)
	var indice := posmod(roundi(angulo / (TAU / 8.0)), 8)
	var orientaciones := [
		"Forward", "Forward_Right", "Right", "Backward_Right",
		"Backward", "Backward_Left", "Left", "Forward_Left"
	]
	return prefijo + orientaciones[indice]


func _configurar_animaciones() -> void:
	if _animacion == null:
		push_error("JugadorBatalla: no se encontró el AnimationPlayer del caballero.")
		return
	for nombre in _animacion.get_animation_list():
		if nombre == "Idle" or nombre.begins_with("Walk_") or nombre.begins_with("Run_"):
			_animacion.get_animation(nombre).loop_mode = Animation.LOOP_LINEAR


func _reproducir_animacion(nombre: String) -> void:
	if _animacion == null or not _animacion.has_animation(nombre):
		return
	if _animacion_actual == nombre and _animacion.is_playing():
		return
	_animacion_actual = nombre
	_animacion.play(nombre)


func _buscar_objetivo() -> Node3D:
	var objetivo_cercano: Node3D
	var distancia_menor := INF
	for nodo in get_tree().get_nodes_in_group("enemigos"):
		if not is_instance_valid(nodo):
			continue
		var distancia := global_position.distance_squared_to(nodo.global_position)
		if distancia < distancia_menor:
			distancia_menor = distancia
			objetivo_cercano = nodo
	return objetivo_cercano
