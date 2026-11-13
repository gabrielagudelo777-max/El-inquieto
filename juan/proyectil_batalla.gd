extends Area3D

@export var velocidad := 23.0

var _direccion := Vector3.FORWARD
var _duracion := 0.0


func _ready() -> void:
	body_entered.connect(_al_impactar)


func configurar_direccion(direccion: Vector3) -> void:
	_direccion = direccion.normalized()


func _physics_process(delta: float) -> void:
	global_position += _direccion * velocidad * delta
	_duracion += delta
	if _duracion >= 1.35:
		queue_free()


func _al_impactar(cuerpo: Node3D) -> void:
	if cuerpo.is_in_group("enemigos") and cuerpo.has_method("recibir_dano"):
		cuerpo.call("recibir_dano", 1)
	queue_free()
