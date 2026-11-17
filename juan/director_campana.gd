extends Node
class_name DirectorCampana

## Estado central de una partida. La lógica de combate se integra mediante
## señales y métodos explícitos; el director no depende del árbol de enemigos.

enum Estado { MENU, INTRO, INTRO_JEFE, COMBATE, INTERMISION, PAUSA, DERROTA, VICTORIA }

const MEJORAS_DISPONIBLES = [
	preload("res://juan/mejoras/impacto_reforzado.tres"),
	preload("res://juan/mejoras/disparo_rapido.tres"),
	preload("res://juan/mejoras/paso_ligero.tres"),
]

signal estado_cambiado(nuevo_estado: int)
signal puntaje_cambiado(actual: int)
signal vidas_cambiadas(actuales: int)
signal oleada_cambiada(indice: int, total: int, nombre: String, es_jefe: bool)
signal oleada_iniciada(indice: int, configuracion: OleadaConfig)
signal cuenta_regresiva(segundos: int)
signal tiempo_cambiado(segundos: int)
signal campana_finalizada(victoria: bool, puntaje: int)
signal recompensas_disponibles(opciones: Array[MejoraConfig])
signal mejora_seleccionada(mejora: MejoraConfig)

@export_group("Campaña")
@export var oleadas: Array[OleadaConfig] = []
@export_range(1, 20, 1) var vidas_iniciales: int = 3
@export_range(0.0, 30.0, 0.5) var duracion_intro: float = 3.0

var estado: Estado = Estado.MENU
var puntaje: int = 0
var vidas: int = 3
var indice_oleada: int = -1
var enemigos_por_derrotar: int = 0
var tiempo_estado: float = 0.0
var tiempo_transcurrido: float = 0.0
var _estado_antes_de_pausar: Estado = Estado.MENU
var _ultimo_segundo_emitido: int = -1
var _ultimo_segundo_partida: int = -1
var _opciones_recompensa: Array[MejoraConfig] = []
var _mejora_pendiente: MejoraConfig
var _recompensa_elegida := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("director_campana")
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
			if _opciones_recompensa.is_empty() or _recompensa_elegida:
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
	_limpiar_recompensa()
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


func seleccionar_mejora(id_mejora: StringName) -> bool:
	if estado != Estado.INTERMISION or _recompensa_elegida:
		return false

	for mejora in _opciones_recompensa:
		if mejora != null and mejora.id == id_mejora:
			_mejora_pendiente = mejora
			_recompensa_elegida = true
			mejora_seleccionada.emit(mejora)
			_ultimo_segundo_emitido = ceili(tiempo_estado)
			cuenta_regresiva.emit(_ultimo_segundo_emitido)
			return true

	return false


func consumir_mejora_pendiente() -> MejoraConfig:
	var mejora := _mejora_pendiente
	_mejora_pendiente = null
	return mejora


func _limpiar_recompensa() -> void:
	_opciones_recompensa.clear()
	_mejora_pendiente = null
	_recompensa_elegida = false


func reiniciar_campana() -> void:
	comenzar_campana()


func volver_al_menu() -> void:
	get_tree().paused = false
	vidas = vidas_iniciales
	puntaje = 0
	indice_oleada = -1
	enemigos_por_derrotar = 0
	_limpiar_recompensa()
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

	var oleada_actual := oleadas[indice_oleada]
	tiempo_estado = oleada_actual.pausa_antes_de_la_siguiente
	if tiempo_estado <= 0.0:
		_iniciar_siguiente_oleada()
		return

	_ultimo_segundo_emitido = -1
	_cambiar_estado(Estado.INTERMISION)
	cuenta_regresiva.emit(ceili(tiempo_estado))

	if oleada_actual.es_jefe:
		_limpiar_recompensa()
		return

	_opciones_recompensa.clear()
	for mejora in MEJORAS_DISPONIBLES:
		if mejora is MejoraConfig:
			_opciones_recompensa.append(mejora)

	_recompensa_elegida = false
	recompensas_disponibles.emit(_opciones_recompensa)


func _sumar_puntos(cantidad: int) -> void:
	if cantidad <= 0:
		return
	puntaje += cantidad
	puntaje_cambiado.emit(puntaje)


func _finalizar(victoria: bool) -> void:
	if estado == Estado.VICTORIA or estado == Estado.DERROTA:
		return
	get_tree().paused = true
	_cambiar_estado(Estado.VICTORIA if victoria else Estado.DERROTA)
	campana_finalizada.emit(victoria, puntaje)


func _cambiar_estado(nuevo_estado: Estado) -> void:
	if estado == nuevo_estado:
		return
	estado = nuevo_estado
	estado_cambiado.emit(estado)


func _emitir_datos_iniciales() -> void:
	puntaje_cambiado.emit(puntaje)
	vidas_cambiadas.emit(vidas)
