extends Area2D

@export var velocidad := 620.0
var _direccion := Vector2.RIGHT
var _danio := 1


func _ready() -> void:
	body_entered.connect(_al_impactar)


func configurar(direccion: Vector2, cantidad_danio: int = 1) -> void:
	_direccion = direccion.normalized()
	_danio = maxi(cantidad_danio, 1)


func _physics_process(delta: float) -> void:
	position += _direccion * velocidad * delta
	if absf(position.x) > 1400.0 or absf(position.y) > 800.0:
		queue_free()


func _al_impactar(cuerpo: Node2D) -> void:
	if cuerpo.is_in_group("enemigos"):
		cuerpo.call("recibir_dano", _danio)
	queue_free()
