extends CharacterBody3D

const PROYECTIL := preload("res://juan/proyectil_batalla.tscn")
const IDLE := preload("res://assets/personaje_16bit/Idle.png")
const CORRER := preload("res://assets/personaje_16bit/Run.png")
const ESQUIVAR := preload("res://assets/personaje_16bit/CrouchRun.png")
const ATACAR := preload("res://assets/personaje_16bit/RunAttack.png")
const DANADO := preload("res://assets/personaje_16bit/TakeDamage.png")

@export var velocidad_movimiento := 5.2
@export var velocidad_dash := 13.5
@export var limite_arena := 8.65

var integridad := 100.0
var _direccion_dash := Vector3.ZERO
var _tiempo_dash := 0.0
var _enfriamiento_disparo := 0.0
var _tiempo_disparo_visual := 0.0
var _tiempo_dano := 0.0
var _tiempo_cuadro := 0.0
var _cuadro := 0
var _fila := 2
var _invulnerabilidad := 0.0
var _director: DirectorCampana
var _personaje: Sprite3D


func _ready() -> void:
	add_to_group("jugador")
	_crear_personaje()
	call_deferred("_conectar_director")


func _physics_process(delta: float) -> void:
	if _director != null and _director.estado != DirectorCampana.Estado.COMBATE:
		velocity = Vector3.ZERO
		return
	_enfriamiento_disparo = maxf(0.0, _enfriamiento_disparo - delta)
	_tiempo_disparo_visual = maxf(0.0, _tiempo_disparo_visual - delta)
	_tiempo_dano = maxf(0.0, _tiempo_dano - delta)
	_tiempo_dash = maxf(0.0, _tiempo_dash - delta)
	_invulnerabilidad = maxf(0.0, _invulnerabilidad - delta)
	_tiempo_cuadro += delta
	if _tiempo_cuadro >= 0.12:
		_tiempo_cuadro = 0.0
		_cuadro = (_cuadro + 1) % 8
	var entrada := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direccion := Vector3(entrada.x, 0.0, entrada.y).normalized()
	if direccion.length_squared() > 0.0:
		_fila = _fila_direccion(direccion)
	if Input.is_action_just_pressed("dash") and direccion.length_squared() > 0.0 and _tiempo_dash <= 0.0:
		_direccion_dash = direccion
		_tiempo_dash = 0.18
		_invulnerabilidad = 0.18
	if _tiempo_dash > 0.0:
		velocity.x = _direccion_dash.x * velocidad_dash
		velocity.z = _direccion_dash.z * velocidad_dash
	else:
		velocity.x = direccion.x * velocidad_movimiento
		velocity.z = direccion.z * velocidad_movimiento
	move_and_slide()
	_actualizar_personaje(direccion)
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
	var modelo := get_node_or_null("Personaje") as Node3D
	if modelo:
		var escala := modelo.scale
		var golpe := create_tween()
		golpe.tween_property(modelo, "scale", escala * 1.08, 0.06)
		golpe.tween_property(modelo, "scale", escala, 0.1)
	_tiempo_dano = 0.24
	if integridad <= 0.0:
		if _director == null:
			_conectar_director()
		if _director != null:
			_director.recibir_impacto()
			if _director.vidas > 0:
				integridad = 100.0


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
	_tiempo_disparo_visual = 0.22
	_fila = _fila_direccion(direccion)
	_actualizar_personaje(Vector3.ZERO)


func _crear_personaje() -> void:
	_personaje = Sprite3D.new()
	_personaje.name = "Personaje"
	_personaje.texture = IDLE
	_personaje.region_enabled = true
	_personaje.region_rect = Rect2(0, 128, 64, 64)
	_personaje.pixel_size = 0.09
	_personaje.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_personaje.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_personaje.position.y = 1.26
	_personaje.modulate = Color(1.0, 0.88, 0.78)
	add_child(_personaje)
	_crear_aura()


func _actualizar_personaje(direccion: Vector3) -> void:
	if not is_instance_valid(_personaje):
		return
	var hoja := IDLE
	if _tiempo_dano > 0.0:
		hoja = DANADO
	elif _tiempo_dash > 0.0:
		hoja = ESQUIVAR
	elif _tiempo_disparo_visual > 0.0:
		hoja = ATACAR
	elif direccion.length_squared() > 0.0:
		hoja = CORRER
	_personaje.texture = hoja
	_personaje.region_rect = Rect2(_cuadro * 64, _fila * 64, 64, 64)


func _fila_direccion(direccion: Vector3) -> int:
	var angulo := atan2(direccion.x, direccion.z)
	return (roundi(angulo / (TAU / 8.0)) + 10) % 8


func _crear_aura() -> void:
	var aura := MeshInstance3D.new()
	var aro := TorusMesh.new()
	aro.inner_radius = 0.78
	aro.outer_radius = 0.86
	aro.rings = 8
	aro.ring_segments = 32
	aura.mesh = aro
	aura.position.y = 0.04
	aura.rotation_degrees.x = 90.0
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.92, 0.52, 0.18)
	material.emission_enabled = true
	material.emission = Color(0.72, 0.22, 0.06)
	material.emission_energy_multiplier = 0.8
	aura.material_override = material
	add_child(aura)


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
