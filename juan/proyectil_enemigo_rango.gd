extends Area2D

@export var velocidad := 420.0
@export var dano := 8.0

var _direccion := Vector2.RIGHT
var _distancia_recorrida := 0.0
const DISTANCIA_MAXIMA := 1200.0


func _ready() -> void:
	body_entered.connect(_al_impactar)


func configurar(direccion: Vector2, cantidad_dano: float, rapidez: float) -> void:
	_direccion = direccion.normalized()
	dano = cantidad_dano
	velocidad = rapidez
	rotation = _direccion.angle() + PI / 2.0


func _physics_process(delta: float) -> void:
	var desplazamiento := _direccion * velocidad * delta
	global_position += desplazamiento
	_distancia_recorrida += desplazamiento.length()
	if _distancia_recorrida >= DISTANCIA_MAXIMA:
		queue_free()


func _al_impactar(cuerpo: Node2D) -> void:
	if cuerpo.is_in_group("jugador") and cuerpo.has_method("recibir_dano"):
		cuerpo.call("recibir_dano", dano)
	queue_free()
