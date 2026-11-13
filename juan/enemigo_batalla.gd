extends CharacterBody3D

@export var velocidad := 1.65
@export var integridad := 3

var _jugador: CharacterBody3D
var _tiempo_ataque := 0.0
var _puntos_recompensa := 100
var _es_jefe := false
var _fue_derrotado := false


func configurar_oleada(rapidez: float, intervalo_ataque: float, puntos: int, es_jefe: bool) -> void:
	velocidad = rapidez
	_tiempo_ataque = intervalo_ataque
	_puntos_recompensa = puntos
	_es_jefe = es_jefe
	if es_jefe:
		integridad = 18


func _ready() -> void:
	add_to_group("enemigos")
	_jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	_crear_marca_ataque()


func _physics_process(delta: float) -> void:
	_tiempo_ataque = maxf(0.0, _tiempo_ataque - delta)
	if not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
		return
	var hacia_jugador := _jugador.global_position - global_position
	hacia_jugador.y = 0.0
	var distancia := hacia_jugador.length()
	if distancia > 1.35:
		var direccion := hacia_jugador.normalized()
		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad
		look_at(global_position + direccion, Vector3.UP)
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		if _tiempo_ataque <= 0.0 and _jugador.has_method("recibir_dano"):
			_jugador.call("recibir_dano", 12.0)
			_tiempo_ataque = 1.0


func recibir_dano(cantidad: int = 1) -> void:
	if _fue_derrotado:
		return
	integridad -= cantidad
	if integridad <= 0:
		_fue_derrotado = true
		var director := get_tree().get_first_node_in_group("director_campana") as DirectorCampana
		if director != null:
			director.registrar_enemigo_derrotado(_puntos_recompensa, _es_jefe)
		queue_free()
		return
	var modelo := get_node_or_null("ModeloAlien") as Node3D
	if modelo:
		var escala_original := modelo.scale
		var tween := create_tween()
		tween.tween_property(modelo, "scale", escala_original * 1.12, 0.07)
		tween.tween_property(modelo, "scale", escala_original, 0.11)


func _crear_marca_ataque() -> void:
	var marca := MeshInstance3D.new()
	var malla := TorusMesh.new()
	malla.inner_radius = 0.42
	malla.outer_radius = 0.48
	malla.rings = 8
	malla.ring_segments = 32
	marca.mesh = malla
	marca.position.y = 0.035
	marca.rotation_degrees.x = 90.0
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.30, 0.23)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.18, 0.12)
	material.emission_energy_multiplier = 1.3
	marca.material_override = material
	add_child(marca)
