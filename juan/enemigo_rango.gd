extends "res://juan/enemigo_isometrico.gd"
class_name EnemigoRango

const PROYECTIL_RANGO = preload("res://juan/proyectil_enemigo_rango.tscn")

@export var distancia_minima := 190.0
@export var distancia_maxima := 460.0
@export var intervalo_disparo_rango := 1.8
@export var velocidad_proyectil_rango := 420.0
@export var dano_proyectil_rango := 8.0

var _enfriamiento_rango := 0.8


func _configurar_intervalo_disparo(intervalo: float) -> void:
	intervalo_disparo_rango = maxf(intervalo, 0.2)


func _ready() -> void:
	super._ready()
	if is_instance_valid(_sprite):
		_sprite.modulate = Color(0.78, 0.88, 1.0)


func _physics_process(delta: float) -> void:
	_enfriamiento_rango = maxf(_enfriamiento_rango - delta, 0.0)

	if not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody2D
		velocity = Vector2.ZERO
		return

	if _director != null and _director.estado != DirectorCampana.Estado.COMBATE:
		velocity = Vector2.ZERO
		return

	var diferencia := _jugador.global_position - global_position
	var distancia := diferencia.length()
	var direccion := diferencia.normalized()

	if distancia > distancia_maxima:
		velocity = direccion * velocidad
	elif distancia < distancia_minima:
		velocity = -direccion * velocidad
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# El sprite mira al jugador aunque retroceda para mantener la distancia.
	_fila = (roundi(direccion.angle() / (TAU / 8.0)) + 12) % 8
	if velocity.length_squared() > 0.0:
		_tiempo_animacion += delta
		if _tiempo_animacion >= 0.14:
			_tiempo_animacion = 0.0
			_cuadro = (_cuadro + 1) % 4
	else:
		_cuadro = 0
	_sprite.region_rect = Rect2(
		_cuadro * TAMANO_CELDA,
		_fila * TAMANO_CELDA,
		TAMANO_CELDA,
		TAMANO_CELDA
	)

	if distancia >= distancia_minima and distancia <= distancia_maxima and _enfriamiento_rango <= 0.0:
		_disparar_hacia_jugador(direccion)


func _disparar_hacia_jugador(direccion: Vector2) -> void:
	var contenedor := get_tree().get_first_node_in_group("contenedor_entidades")
	if contenedor == null:
		return

	var proyectil := PROYECTIL_RANGO.instantiate() as Area2D
	contenedor.add_child(proyectil)
	proyectil.global_position = global_position + direccion * 28.0 + Vector2(0.0, -20.0)
	proyectil.call("configurar", direccion, dano_proyectil_rango, velocidad_proyectil_rango)
	_enfriamiento_rango = intervalo_disparo_rango
