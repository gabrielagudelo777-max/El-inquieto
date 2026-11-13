extends CanvasLayer
class_name UICampana

## Menú, HUD y pantallas de flujo. Conecta sus datos mediante señales del director.

@onready var hud: Control = $HUD
@onready var lbl_vidas: Label = $HUD/Barra/Fila/Vidas
@onready var lbl_oleada: Label = $HUD/Barra/Fila/Oleada
@onready var lbl_puntaje: Label = $HUD/Barra/Fila/Puntaje
@onready var lbl_record: Label = $HUD/Barra/Fila/Record
@onready var lbl_tiempo: Label = $HUD/Barra/Fila/Tiempo
@onready var lbl_estado: Label = $HUD/Centro/EstadoCombate
@onready var overlay: Control = $Overlay
@onready var lbl_titulo: Label = $Overlay/Centro/Panel/Contenido/Titulo
@onready var lbl_detalle: Label = $Overlay/Centro/Panel/Contenido/Detalle
@onready var btn_principal: Button = $Overlay/Centro/Panel/Contenido/BotonPrincipal
@onready var btn_menu: Button = $Overlay/Centro/Panel/Contenido/BotonMenu

var director: DirectorCampana
var estado_actual: int = DirectorCampana.Estado.MENU


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	btn_principal.pressed.connect(_al_pulsar_principal)
	btn_menu.pressed.connect(_al_pulsar_menu)
	call_deferred("_conectar_director")


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or director == null:
		return
	if estado_actual == DirectorCampana.Estado.INTRO or estado_actual == DirectorCampana.Estado.INTRO_JEFE:
		_saltar_cinematica()
		director.saltar_intro()
		get_viewport().set_input_as_handled()
	elif estado_actual == DirectorCampana.Estado.COMBATE or estado_actual == DirectorCampana.Estado.INTERMISION:
		director.pausar()
		get_viewport().set_input_as_handled()
	elif estado_actual == DirectorCampana.Estado.PAUSA:
		director.reanudar()
		get_viewport().set_input_as_handled()


func _conectar_director() -> void:
	director = get_tree().get_first_node_in_group("director_campana") as DirectorCampana
	if director == null:
		push_error("UICampana: falta el nodo DirectorCampana en la escena.")
		return
	director.estado_cambiado.connect(_actualizar_estado)
	director.puntaje_cambiado.connect(_actualizar_puntaje)
	director.vidas_cambiadas.connect(_actualizar_vidas)
	director.oleada_cambiada.connect(_actualizar_oleada)
	director.cuenta_regresiva.connect(_actualizar_cuenta_regresiva)
	director.tiempo_cambiado.connect(_actualizar_tiempo)
	director.campana_finalizada.connect(_mostrar_resultado)
	_actualizar_puntaje(director.puntaje, director.record)
	_actualizar_vidas(director.vidas)
	_actualizar_tiempo(floori(director.tiempo_transcurrido))
	_actualizar_estado(director.estado)


func _actualizar_estado(nuevo: int) -> void:
	estado_actual = nuevo
	var mostrar_overlay := true
	btn_menu.hide()
	btn_principal.show()
	lbl_estado.text = ""
	match nuevo:
		DirectorCampana.Estado.MENU:
			lbl_titulo.text = "EL INQUIETO"
			lbl_detalle.text = "ASALTO // PROTOTIPO PARA PC\n\nSobrevive a las formaciones. Muévete, dispara y encuentra el momento para esquivar.\n\nWASD o flechas: mover   ·   Espacio: disparar\nCtrl: correr   ·   Shift: dash   ·   Esc: pausa"
			btn_principal.text = "INICIAR CAMPAÑA"
		DirectorCampana.Estado.INTRO:
			lbl_titulo.text = "SEÑAL DE ALERTA"
			lbl_detalle.text = "Lectura de movimiento enemigo detectada…"
			btn_principal.text = "SALTAR INTRO"
			_reproducir_intro()
		DirectorCampana.Estado.INTRO_JEFE:
			lbl_titulo.text = "AMENAZA DE ALTA TENDENCIA"
			lbl_detalle.text = "Una figura domina la formación."
			btn_principal.text = "SALTAR PRESENTACIÓN"
			var config: OleadaConfig = director.oleadas[director.indice_oleada]
			_presentar_jefe(config.nombre)
		DirectorCampana.Estado.COMBATE:
			mostrar_overlay = false
			lbl_estado.text = ""
		DirectorCampana.Estado.INTERMISION:
			lbl_titulo.text = "OLEADA COMPLETADA"
			lbl_detalle.text = "Recupera el aliento."
			btn_principal.hide()
		DirectorCampana.Estado.PAUSA:
			lbl_titulo.text = "PAUSA"
			lbl_detalle.text = "La partida está detenida."
			btn_principal.text = "CONTINUAR"
			btn_menu.show()
			btn_menu.text = "VOLVER AL MENÚ"
		DirectorCampana.Estado.DERROTA:
			lbl_titulo.text = "FIN DE LA PARTIDA"
			lbl_detalle.text = ""
			btn_principal.text = "REINTENTAR"
			btn_menu.show()
			btn_menu.text = "MENÚ PRINCIPAL"
		DirectorCampana.Estado.VICTORIA:
			lbl_titulo.text = "¡VICTORIA!"
			lbl_detalle.text = "La arena vuelve a estar en calma."
			btn_principal.text = "JUGAR DE NUEVO"
			btn_menu.show()
			btn_menu.text = "MENÚ PRINCIPAL"
	_overlay_actualizar(mostrar_overlay)


func _overlay_actualizar(mostrar: bool) -> void:
	overlay.visible = mostrar
	hud.visible = estado_actual != DirectorCampana.Estado.MENU


func _actualizar_puntaje(actual: int, record: int) -> void:
	lbl_puntaje.text = "PUNTAJE  %06d" % actual
	lbl_record.text = "RÉCORD  %06d" % record


func _actualizar_vidas(actuales: int) -> void:
	lbl_vidas.text = "VIDAS  %d" % actuales


func _actualizar_oleada(indice: int, total: int, nombre: String, es_jefe: bool) -> void:
	var etiqueta := "JEFE" if es_jefe else "OLEADA"
	lbl_oleada.text = "%s  %02d / %02d  ·  %s" % [etiqueta, indice, total, nombre.to_upper()]


func _actualizar_cuenta_regresiva(segundos: int) -> void:
	if estado_actual == DirectorCampana.Estado.INTERMISION:
		lbl_detalle.text = "La siguiente formación llega en %d…" % segundos


func _actualizar_tiempo(segundos: int) -> void:
	var minutos := floori(float(segundos) / 60.0)
	var resto := segundos % 60
	lbl_tiempo.text = "TIEMPO  %02d:%02d" % [minutos, resto]


func _mostrar_resultado(victoria: bool, puntaje: int, record: int) -> void:
	if victoria:
		lbl_detalle.text = "Campaña completada\nPuntaje: %06d   ·   Récord: %06d" % [puntaje, record]
	else:
		lbl_detalle.text = "Puntaje: %06d   ·   Récord: %06d" % [puntaje, record]


func _al_pulsar_principal() -> void:
	if director == null:
		return
	match estado_actual:
		DirectorCampana.Estado.MENU:
			director.comenzar_campana()
		DirectorCampana.Estado.INTRO:
			_saltar_cinematica()
			director.saltar_intro()
		DirectorCampana.Estado.INTRO_JEFE:
			_saltar_cinematica()
			director.saltar_intro()
		DirectorCampana.Estado.PAUSA:
			director.reanudar()
		DirectorCampana.Estado.DERROTA, DirectorCampana.Estado.VICTORIA:
			director.reiniciar_campana()


func _al_pulsar_menu() -> void:
	var error := get_tree().change_scene_to_file("res://escenas/main_menu.tscn")
	if error != OK:
		push_error("No se pudo volver al menú principal: %s" % error_string(error))


func _reproducir_intro() -> void:
	var cinematica := get_tree().get_first_node_in_group("cinematicas") as CinematicasEscenario
	if cinematica != null:
		cinematica.reproducir_intro()


func _presentar_jefe(nombre: String) -> void:
	var cinematica := get_tree().get_first_node_in_group("cinematicas") as CinematicasEscenario
	if cinematica != null:
		cinematica.presentar_jefe(nombre)


func _saltar_cinematica() -> void:
	var cinematica := get_tree().get_first_node_in_group("cinematicas") as CinematicasEscenario
	if cinematica != null:
		cinematica.saltar_cinematica()
