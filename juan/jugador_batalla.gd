extends CharacterBody3D

const PROYECTIL := preload("res://juan/proyectil_batalla.tscn")

@export var velocidad_movimiento := 5.2
@export var velocidad_dash := 13.5
@export var limite_arena := 8.65

var integridad := 100.0
var _direccion_dash := Vector3.ZERO
var _tiempo_dash := 0.0
var _enfriamiento_disparo := 0.0
var _invulnerabilidad := 0.0
var _director: DirectorCampana


func _ready() -> void:
	add_to_group("jugador")
	call_deferred("_conectar_director")


func _physics_process(delta: float) -> void:
	if _director != null and _director.estado != DirectorCampana.Estado.COMBATE:
		velocity = Vector3.ZERO
		return
	_enfriamiento_disparo = maxf(0.0, _enfriamiento_disparo - delta)
	_tiempo_dash = maxf(0.0, _tiempo_dash - delta)
	_invulnerabilidad = maxf(0.0, _invulnerabilidad - delta)
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
	if Input.is_action_pressed("disparar") and _enfriamiento_disparo <= 0.0:
		_disparar()
		_enfriamiento_disparo = 0.28


func recibir_dano(cantidad: float) -> void:
	if _invulnerabilidad > 0.0:
		return
	integridad = maxf(0.0, integridad - cantidad)
	_invulnerabilidad = 0.55
	var arena := get_tree().get_first_node_in_group("control_arena")
	if arena and arena.has_method("mostrar_mensaje"):
		arena.call("mostrar_mensaje", "IMPACTO EN EL TRAJE")
	if integridad <= 0.0 and arena and arena.has_method("mostrar_mensaje"):
		arena.call("mostrar_mensaje", "INTEGRIDAD AGOTADA  //  ESC PARA VOLVER")
	if integridad <= 0.0:
		if _director == null:
			_conectar_director()
		if _director != null:
			_director.recibir_impacto()
			if _director.vidas > 0:
				integridad = 100.0
				if arena and arena.has_method("mostrar_mensaje"):
					arena.call("mostrar_mensaje", "TRAJE RESTAURADO  //  VIDAS %d" % _director.vidas)


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
