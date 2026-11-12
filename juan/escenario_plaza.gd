extends Node3D
class_name EscenarioPlaza

## Blockout 3D de la arena. Se juega en X/Z; Y se reserva para alturas.

@export var objetivo_camara: Vector3 = Vector3(0.0, 0.0, 0.0)
@export var limites_jugador := Vector2(12.5, 9.0)

@onready var camara: Camera3D = $CamaraIsometrica


func _ready() -> void:
	add_to_group("escenario_plaza")
	camara.look_at(objetivo_camara, Vector3.UP)


func limitar_posicion_jugador(posicion: Vector3) -> Vector3:
	posicion.x = clampf(posicion.x, -limites_jugador.x, limites_jugador.x)
	posicion.z = clampf(posicion.z, -limites_jugador.y, limites_jugador.y)
	return posicion
