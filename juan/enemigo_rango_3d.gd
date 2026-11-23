extends "res://juan/enemigo_batalla.gd"
class_name EnemigoRango3D

const PROYECTIL_RANGO = preload("res://juan/proyectil_enemigo_rango_3d.tscn")

@export var distancia_minima := 3.8
@export var distancia_maxima := 6.4
@export var velocidad_proyectil_rango := 13.0
@export var dano_proyectil_rango := 10.0


func _physics_process(delta: float) -> void:
	_tiempo_ataque = maxf(0.0, _tiempo_ataque - delta)
	if not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
		return

	var diferencia := _jugador.global_position - global_position
	diferencia.y = 0.0
	var distancia := diferencia.length()
	var direccion := diferencia.normalized()
	if distancia > distancia_maxima:
		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad
		look_at(global_position + direccion, Vector3.UP)
	elif distancia < distancia_minima:
		velocity.x = -direccion.x * velocidad
		velocity.z = -direccion.z * velocidad
		look_at(global_position + direccion, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
	if distancia >= distancia_minima and distancia <= distancia_maxima and _tiempo_ataque <= 0.0:
		_disparar_hacia_jugador(direccion)


func _disparar_hacia_jugador(direccion: Vector3) -> void:
	var proyectil := PROYECTIL_RANGO.instantiate() as Area3D
	get_tree().current_scene.add_child(proyectil)
	proyectil.global_position = global_position + Vector3.UP * 0.85 + direccion * 0.72
	proyectil.call("configurar", direccion, dano_proyectil_rango, velocidad_proyectil_rango)
	_tiempo_ataque = _intervalo_ataque
