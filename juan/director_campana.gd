extends Node
class_name DirectorCampana

## Estado central de una partida. La lógica de combate se integra mediante
## señales y métodos explícitos; el director no depende del árbol de enemigos.

enum Estado { MENU, INTRO, INTRO_JEFE, COMBATE, INTERMISION, PAUSA, DERROTA, VICTORIA }

signal estado_cambiado(nuevo_estado: int)
signal puntaje_cambiado(actual: int, record: int)
signal vidas_cambiadas(actuales: int)
signal oleada_cambiada(indice: int, total: int, nombre: String, es_jefe: bool)
signal oleada_iniciada(indice: int, configuracion: OleadaConfig)
signal cuenta_regresiva(segundos: int)
signal tiempo_cambiado(segundos: int)
signal campana_finalizada(victoria: bool, puntaje: int, record: int)

const ARCHIVO_RECORD := "user://el_inquieto_record.cfg"

@export_group("Campaña")
@export var oleadas: Array[OleadaConfig] = []
@export_range(1, 20, 1) var vidas_iniciales: int = 3
@export_range(0.0, 30.0, 0.5) var duracion_intro: float = 3.0

var estado: Estado = Estado.MENU
var puntaje: int = 0
var record: int = 0
var vidas: int = 3
var indice_oleada: int = -1
var enemigos_por_derrotar: int = 0
var tiempo_estado: float = 0.0
var tiempo_transcurrido: float = 0.0
var _estado_antes_de_pausar: Estado = Estado.MENU
var _ultimo_segundo_emitido: int = -1
var _ultimo_segundo_partida: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("director_campana")
	record = _cargar_record()
	vidas = vidas_iniciales
	_emitir_datos_iniciales()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if estado != Estado.MENU and estado != Estado.DERROTA and estado != Estado.VICTORIA:
		tiempo_transcurrido += delta
		var segundo_partida := floori(tiempo_transcurrido)
		if segundo_partida != _ultimo_segundo_partida:
			_ultimo_segundo_partida = segundo_partida
			tiempo_cambiado.emit(segundo_partida)
	match estado:
		Estado.INTRO:
			tiempo_estado = maxf(tiempo_estado - delta, 0.0)
			if tiempo_estado <= 0.0:
				_iniciar_siguiente_oleada()
		Estado.INTRO_JEFE:
			tiempo_estado = maxf(tiempo_estado - delta, 0.0)
			if tiempo_estado <= 0.0:
				_activar_oleada_actual()
		Estado.INTERMISION:
			tiempo_estado = maxf(tiempo_estado - delta, 0.0)
			var segundo := ceili(tiempo_estado)
			if segundo != _ultimo_segundo_emitido:
				_ultimo_segundo_emitido = segundo
				cuenta_regresiva.emit(segundo)
			if tiempo_estado <= 0.0:
				_iniciar_siguiente_oleada()


func comenzar_campana() -> void:
	if oleadas.is_empty():
		push_error("DirectorCampana: asigna los recursos de oleada en el Inspector.")
		return

	get_tree().paused = false
	puntaje = 0
	vidas = vidas_iniciales
	indice_oleada = -1
	enemigos_por_derrotar = 0
	tiempo_transcurrido = 0.0
	_ultimo_segundo_partida = -1
	tiempo_cambiado.emit(0)
	_emitir_datos_iniciales()
	tiempo_estado = duracion_intro
	_cambiar_estado(Estado.INTRO if duracion_intro > 0.0 else Estado.COMBATE)
	if duracion_intro <= 0.0:
		_iniciar_siguiente_oleada()


func saltar_intro() -> void:
	match estado:
		Estado.INTRO:
			tiempo_estado = 0.0
			_iniciar_siguiente_oleada()
		Estado.INTRO_JEFE:
			tiempo_estado = 0.0
			_activar_oleada_actual()


func pausar() -> void:
	if estado != Estado.COMBATE and estado != Estado.INTERMISION:
		return
	_estado_antes_de_pausar = estado
	get_tree().paused = true
	_cambiar_estado(Estado.PAUSA)


func reanudar() -> void:
	if estado != Estado.PAUSA:
		return
	get_tree().paused = false
	_cambiar_estado(_estado_antes_de_pausar)


func alternar_pausa() -> void:
	if estado == Estado.PAUSA:
		reanudar()
	else:
		pausar()


func registrar_enemigo_derrotado(puntos: int = -1, es_jefe: bool = false) -> void:
	if estado != Estado.COMBATE or enemigos_por_derrotar <= 0:
		return
	var recompensa: int = puntos
	if recompensa < 0:
		recompensa = oleadas[indice_oleada].puntos_por_enemigo
	_sumar_puntos(recompensa)
	enemigos_por_derrotar -= 1
	if es_jefe or enemigos_por_derrotar == 0:
		_completar_oleada()


func recibir_impacto(cantidad: int = 1) -> void:
	if estado != Estado.COMBATE or cantidad <= 0:
		return
	vidas = maxi(vidas - cantidad, 0)
	vidas_cambiadas.emit(vidas)
	if vidas == 0:
		_finalizar(false)


func otorgar_vida(cantidad: int = 1) -> void:
	if estado != Estado.COMBATE or cantidad <= 0:
		return
	vidas += cantidad
	vidas_cambiadas.emit(vidas)


func reiniciar_campana() -> void:
	comenzar_campana()


func volver_al_menu() -> void:
	get_tree().paused = false
	vidas = vidas_iniciales
	puntaje = 0
	indice_oleada = -1
	enemigos_por_derrotar = 0
	tiempo_transcurrido = 0.0
	_ultimo_segundo_partida = -1
	tiempo_cambiado.emit(0)
	_emitir_datos_iniciales()
	_cambiar_estado(Estado.MENU)


func _iniciar_siguiente_oleada() -> void:
	indice_oleada += 1
	if indice_oleada >= oleadas.size():
		_finalizar(true)
		return
	var config: OleadaConfig = oleadas[indice_oleada]
	if config.es_jefe:
		tiempo_estado = duracion_jefe_intro()
		_cambiar_estado(Estado.INTRO_JEFE)
		return
	_activar_oleada_actual()


func duracion_jefe_intro() -> float:
	return 2.5


func _activar_oleada_actual() -> void:
	var config: OleadaConfig = oleadas[indice_oleada]
	enemigos_por_derrotar = config.cantidad_enemigos
	_ultimo_segundo_emitido = -1
	_cambiar_estado(Estado.COMBATE)
	oleada_cambiada.emit(indice_oleada + 1, oleadas.size(), config.nombre, config.es_jefe)
	oleada_iniciada.emit(indice_oleada + 1, config)


func _completar_oleada() -> void:
	if indice_oleada + 1 >= oleadas.size():
		_finalizar(true)
		return
	tiempo_estado = oleadas[indice_oleada].pausa_antes_de_la_siguiente
	if tiempo_estado <= 0.0:
		_iniciar_siguiente_oleada()
		return
	_ultimo_segundo_emitido = -1
	_cambiar_estado(Estado.INTERMISION)
	cuenta_regresiva.emit(ceili(tiempo_estado))


func _sumar_puntos(cantidad: int) -> void:
	if cantidad <= 0:
		return
	puntaje += cantidad
	if puntaje > record:
		record = puntaje
		_guardar_record()
	puntaje_cambiado.emit(puntaje, record)


func _finalizar(victoria: bool) -> void:
	if estado == Estado.VICTORIA or estado == Estado.DERROTA:
		return
	get_tree().paused = true
	_cambiar_estado(Estado.VICTORIA if victoria else Estado.DERROTA)
	campana_finalizada.emit(victoria, puntaje, record)


func _cambiar_estado(nuevo_estado: Estado) -> void:
	if estado == nuevo_estado:
		return
	estado = nuevo_estado
	estado_cambiado.emit(estado)


func _emitir_datos_iniciales() -> void:
	puntaje_cambiado.emit(puntaje, record)
	vidas_cambiadas.emit(vidas)


func _cargar_record() -> int:
	var archivo := ConfigFile.new()
	if archivo.load(ARCHIVO_RECORD) != OK:
		return 0
	return maxi(int(archivo.get_value("campana", "record", 0)), 0)


func _guardar_record() -> void:
	var archivo := ConfigFile.new()
	archivo.set_value("campana", "record", record)
	var error := archivo.save(ARCHIVO_RECORD)
	if error != OK:
		push_warning("No se pudo guardar el récord local: %s" % error_string(error))
