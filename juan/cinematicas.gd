extends Node
class_name CinematicasEscenario

## Secuencias breves de cámara/títulos. El combate escucha
## control_jugador_bloqueado para desactivar el movimiento mientras corre.

signal cinematica_iniciada(tipo: StringName)
signal cinematica_finalizada(tipo: StringName)
signal control_jugador_bloqueado(bloqueado: bool)

@export var duracion_intro: float = 3.0
@export var duracion_jefe: float = 2.5

@onready var camara: Camera3D = get_node("../CamaraIsometrica")
@onready var cortina: Control = get_node("../InterfazCinematica/Cortina")
@onready var titulo: Label = get_node("../InterfazCinematica/Cortina/Contenido/Titulo")
@onready var detalle: Label = get_node("../InterfazCinematica/Cortina/Contenido/Detalle")

var _tween: Tween
var _tipo_actual: StringName = &""
var _posicion_camara_base: Vector3
var _tamano_camara_base: float


func _ready() -> void:
	_posicion_camara_base = camara.position
	_tamano_camara_base = camara.size
	cortina.hide()
	add_to_group("cinematicas")


func reproducir_intro() -> void:
	_reproducir(&"intro", "LA PLAZA DEL REENVÍO", "Una señal viral ha despertado la ciudad.", duracion_intro, 1.0)


func presentar_jefe(nombre: String) -> void:
	_reproducir(&"jefe", nombre.to_upper(), "AMENAZA DE ALTA TENDENCIA", duracion_jefe, 1.18)


func saltar_cinematica() -> void:
	if _tipo_actual == &"":
		return
	var tipo := _tipo_actual
	if _tween != null and _tween.is_running():
		_tween.kill()
	_restaurar_camara()
	cortina.hide()
	_tipo_actual = &""
	control_jugador_bloqueado.emit(false)
	cinematica_finalizada.emit(tipo)


func _reproducir(tipo: StringName, encabezado: String, texto: String, duracion: float, zoom: float) -> void:
	saltar_cinematica()
	_tipo_actual = tipo
	titulo.text = encabezado
	detalle.text = texto
	cortina.show()
	camara.position = _posicion_camara_base + Vector3(0.0, 4.0, 4.0)
	camara.size = _tamano_camara_base * zoom
	control_jugador_bloqueado.emit(true)
	cinematica_iniciada.emit(tipo)

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(camara, "position", _posicion_camara_base, duracion)
	_tween.tween_property(camara, "size", _tamano_camara_base, duracion)
	_tween.chain().tween_callback(_finalizar.bind(tipo))


func _finalizar(tipo: StringName) -> void:
	if _tipo_actual != tipo:
		return
	_restaurar_camara()
	cortina.hide()
	_tipo_actual = &""
	control_jugador_bloqueado.emit(false)
	cinematica_finalizada.emit(tipo)


func _restaurar_camara() -> void:
	camara.position = _posicion_camara_base
	camara.size = _tamano_camara_base
