extends Area3D

@export var velocidad := 13.0
@export var dano := 10.0

var _direccion := Vector3.FORWARD
var _duracion := 0.0
const DURACION_MAXIMA := 2.5


func _ready() -> void:
	body_entered.connect(_al_impactar)


func configurar(direccion: Vector3, cantidad_dano: float, rapidez: float) -> void:
	_direccion = direccion.normalized()
	dano = cantidad_dano
	velocidad = rapidez
	look_at(global_position + _direccion, Vector3.UP)


func _physics_process(delta: float) -> void:
	global_position += _direccion * velocidad * delta
	_duracion += delta
	if _duracion >= DURACION_MAXIMA:
		queue_free()


func _al_impactar(cuerpo: Node3D) -> void:
	if cuerpo.is_in_group("jugador") and cuerpo.has_method("recibir_dano"):
		cuerpo.call("recibir_dano", dano)
	queue_free()
