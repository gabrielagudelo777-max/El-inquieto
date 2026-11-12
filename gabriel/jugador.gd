extends CharacterBody3D

@export var velocidad_caminar := 3.0
@export var velocidad_correr := 6.0
@export var tiempo_aceleracion := 0.25

var _puede_moverse := false
var _director: DirectorCampana


func _ready() -> void:
	add_to_group("jugador")
	var animacion := $Astronaut.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animacion and animacion.has_animation("CharacterArmature|Idle_Gun"):
		animacion.play("CharacterArmature|Idle_Gun")
	call_deferred("_conectar_senales")


func _physics_process(delta: float) -> void:
	if not _puede_moverse:
		velocity = Vector3.ZERO
		return

	var entrada := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var velocidad := velocidad_correr if Input.is_action_pressed("correr") else velocidad_caminar
	var cambio := velocidad / maxf(tiempo_aceleracion, 0.01) * delta
	velocity.x = move_toward(velocity.x, entrada.x * velocidad, cambio)
	velocity.z = move_toward(velocity.z, entrada.y * velocidad, cambio)
	move_and_slide()

	var escenario := get_parent() as EscenarioPlaza
	if escenario:
		position = escenario.limitar_posicion_jugador(position)


func _conectar_senales() -> void:
	_director = get_tree().get_first_node_in_group("director_campana") as DirectorCampana
	if _director:
		_director.estado_cambiado.connect(_cambiar_estado)
		_cambiar_estado(_director.estado)

	var cinematica := get_tree().get_first_node_in_group("cinematicas") as CinematicasEscenario
	if cinematica:
		cinematica.control_jugador_bloqueado.connect(_bloquear_por_cinematica)


func _cambiar_estado(estado: int) -> void:
	_puede_moverse = estado == DirectorCampana.Estado.COMBATE


func _bloquear_por_cinematica(bloqueado: bool) -> void:
	_puede_moverse = not bloqueado and _director != null and _director.estado == DirectorCampana.Estado.COMBATE
