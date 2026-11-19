extends CanvasLayer
class_name UICampana

## Menú, HUD y pantallas de flujo. Conecta sus datos mediante señales del director.

const NOMBRES_CAMARAS := [
	"Atrio de las Cenizas",
	"Galería Carmesí",
	"Foso del Eclipse",
	"Santuario de Brasa",
	"Pasaje de los Ecos",
	"Salón del Vigía",
]
const FUENTE_UI = preload("res://assets/fonts/CinzelDecorative-Regular.ttf")

@onready var hud: Control = $HUD
@onready var lbl_vidas: Label = $HUD/Barra/Fila/Vidas
@onready var lbl_oleada: Label = $HUD/Barra/Fila/Oleada
@onready var lbl_puntaje: Label = $HUD/Barra/Fila/Puntaje
@onready var lbl_tiempo: Label = $HUD/Barra/Fila/Tiempo
@onready var overlay: Control = $Overlay
@onready var lbl_sello: Label = $Overlay/Centro/Panel/Contenido/Sello
@onready var lbl_titulo: Label = $Overlay/Centro/Panel/Contenido/Titulo
@onready var lbl_detalle: Label = $Overlay/Centro/Panel/Contenido/Detalle
@onready var btn_principal: Button = $Overlay/Centro/Panel/Contenido/BotonPrincipal
@onready var btn_menu: Button = $Overlay/Centro/Panel/Contenido/BotonMenu

var director: DirectorCampana
var estado_actual: int = DirectorCampana.Estado.MENU
var mostrar_hud := true
var _contenedor_recompensas: HBoxContainer
var _opciones_recompensa: Array[MejoraConfig] = []
var _recompensa_elegida := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_aplicar_estilo()
	_crear_contenedor_recompensas()
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
	director.recompensas_disponibles.connect(_mostrar_recompensas)
	director.mejora_seleccionada.connect(_al_seleccionar_mejora)
	_actualizar_puntaje(director.puntaje)
	_actualizar_vidas(director.vidas)
	_actualizar_tiempo(floori(director.tiempo_transcurrido))
	_actualizar_estado(director.estado)


func _actualizar_estado(nuevo: int) -> void:
	estado_actual = nuevo
	$Overlay/Centro/Panel.custom_minimum_size.x = 620.0
	lbl_detalle.custom_minimum_size.y = 148.0
	if is_instance_valid(_contenedor_recompensas):
		_contenedor_recompensas.hide()
	if nuevo == DirectorCampana.Estado.COMBATE or nuevo == DirectorCampana.Estado.MENU:
		_opciones_recompensa.clear()
		_recompensa_elegida = false
	var mostrar_overlay := true
	btn_menu.hide()
	btn_principal.show()
	match nuevo:
		DirectorCampana.Estado.MENU:
			lbl_sello.text = "DESCENSO A LA ARENA"
			lbl_titulo.text = "EL INQUIETO"
			lbl_detalle.text = "ASALTO ARCADE\n\nSobrevive a las formaciones. Muévete, dispara y encuentra el momento para esquivar.\n\nWASD / FLECHAS  ·  MOVER\nESPACIO  ·  DISPARAR\nCTRL  ·  CORRER     SHIFT  ·  ESQUIVAR\nESC  ·  PAUSA"
			btn_principal.text = "INICIAR CAMPAÑA"
		DirectorCampana.Estado.INTRO:
			mostrar_overlay = false
			_reproducir_intro()
		DirectorCampana.Estado.INTRO_JEFE:
			mostrar_overlay = false
			var config: OleadaConfig = director.oleadas[director.indice_oleada]
			_presentar_jefe(config.nombre)
		DirectorCampana.Estado.COMBATE:
			mostrar_overlay = false
		DirectorCampana.Estado.INTERMISION:
			lbl_sello.text = "EL UMBRAL ENTRE COMBATES"
			lbl_titulo.text = "SALA COMPLETADA"
			lbl_detalle.text = "El siguiente portal se abrirá en un momento."
			btn_principal.hide()
		DirectorCampana.Estado.PAUSA:
			lbl_sello.text = "EL TIEMPO SE DETIENE"
			lbl_titulo.text = "PAUSA"
			lbl_detalle.text = "La partida está detenida."
			btn_principal.text = "CONTINUAR"
			btn_menu.show()
			btn_menu.text = "VOLVER AL MENÚ"
		DirectorCampana.Estado.DERROTA:
			lbl_sello.text = "CAMPAÑA INTERRUMPIDA"
			lbl_titulo.text = "DERROTA"
			lbl_detalle.text = ""
			btn_principal.text = "REINTENTAR"
			btn_menu.show()
			btn_menu.text = "MENÚ PRINCIPAL"
		DirectorCampana.Estado.VICTORIA:
			lbl_sello.text = "EL CICLO HA SIDO ROTO"
			lbl_titulo.text = "VICTORIA"
			lbl_detalle.text = "La arena vuelve a estar en calma."
			btn_principal.text = "JUGAR DE NUEVO"
			btn_menu.show()
			btn_menu.text = "MENÚ PRINCIPAL"
	if nuevo == DirectorCampana.Estado.DERROTA:
		lbl_titulo.add_theme_color_override("font_color", Color(0.82, 0.43, 0.31))
	else:
		lbl_titulo.add_theme_color_override("font_color", Color(0.93, 0.83, 0.61))
	if nuevo == DirectorCampana.Estado.INTERMISION and not _opciones_recompensa.is_empty() and not _recompensa_elegida:
		_mostrar_recompensas(_opciones_recompensa)
	_overlay_actualizar(mostrar_overlay)


func _overlay_actualizar(mostrar: bool) -> void:
	overlay.visible = mostrar
	hud.visible = mostrar_hud and estado_actual != DirectorCampana.Estado.MENU


func _crear_contenedor_recompensas() -> void:
	_contenedor_recompensas = VBoxContainer.new()
	_contenedor_recompensas.name = "OpcionesMejora"
	_contenedor_recompensas.custom_minimum_size = Vector2(0.0, 270.0)
	_contenedor_recompensas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenedor_recompensas.add_theme_constant_override("separation", 8)
	_contenedor_recompensas.hide()

	var contenido := $Overlay/Centro/Panel/Contenido as VBoxContainer
	contenido.add_child(_contenedor_recompensas)
	contenido.move_child(
		_contenedor_recompensas,
		btn_principal.get_index()
	)


func _mostrar_recompensas(opciones: Array[MejoraConfig]) -> void:
	if estado_actual != DirectorCampana.Estado.INTERMISION:
		return

	_opciones_recompensa.clear()
	for mejora in opciones:
		if mejora != null:
			_opciones_recompensa.append(mejora)

	_recompensa_elegida = false
	_limpiar_tarjetas_recompensa()
	$Overlay/Centro/Panel.custom_minimum_size.x = 850.0
	lbl_detalle.custom_minimum_size.y = 42.0
	lbl_titulo.text = "ELIGE UNA MEJORA"
	lbl_detalle.text = "EL FAVOR ELEGIDO TE ACOMPAÑARÁ EN EL SIGUIENTE COMBATE"
	btn_principal.hide()
	btn_menu.hide()

	for indice in _opciones_recompensa.size():
		_contenedor_recompensas.add_child(
			_crear_tarjeta_recompensa(_opciones_recompensa[indice], indice)
		)

	_contenedor_recompensas.show()
	if _contenedor_recompensas.get_child_count() > 0:
		(_contenedor_recompensas.get_child(0) as Button).grab_focus()


func _crear_tarjeta_recompensa(mejora: MejoraConfig, indice: int) -> Button:
	var boton := Button.new()
	boton.name = "Mejora_" + String(mejora.id)
	boton.custom_minimum_size = Vector2(0.0, 82.0)
	boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boton.focus_mode = Control.FOCUS_ALL
	boton.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.045, 0.032, 0.03, 0.96)
	estilo.border_color = Color(0.38, 0.27, 0.18, 0.9)
	estilo.set_border_width_all(1)
	estilo.set_content_margin_all(10)
	boton.add_theme_stylebox_override("normal", estilo)

	var encima := estilo.duplicate() as StyleBoxFlat
	encima.bg_color = Color(0.13, 0.075, 0.045, 0.99)
	encima.border_color = Color(0.91, 0.69, 0.34, 1.0)
	encima.set_border_width_all(2)
	boton.add_theme_stylebox_override("hover", encima)
	boton.add_theme_stylebox_override("pressed", encima)
	boton.add_theme_stylebox_override("focus", encima)

	var fila := HBoxContainer.new()
	fila.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fila.add_theme_constant_override("separation", 16)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton.add_child(fila)

	var emblema := Panel.new()
	emblema.custom_minimum_size = Vector2(56.0, 56.0)
	var estilo_emblema := StyleBoxFlat.new()
	estilo_emblema.bg_color = Color(0.075, 0.045, 0.04, 1.0)
	estilo_emblema.border_color = Color(0.67, 0.48, 0.25, 0.9)
	estilo_emblema.set_border_width_all(1)
	estilo_emblema.set_corner_radius_all(2)
	emblema.add_theme_stylebox_override("panel", estilo_emblema)
	emblema.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(emblema)

	var numero := Label.new()
	numero.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	numero.text = ["I", "II", "III"][mini(indice, 2)]
	numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	numero.add_theme_font_override("font", FUENTE_UI)
	numero.add_theme_font_size_override("font_size", 22)
	numero.add_theme_color_override("font_color", Color(0.91, 0.73, 0.43))
	numero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emblema.add_child(numero)

	var contenido := VBoxContainer.new()
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenido.add_theme_constant_override("separation", 4)
	contenido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(contenido)

	var titulo := Label.new()
	titulo.text = mejora.nombre
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	titulo.add_theme_font_override("font", FUENTE_UI)
	titulo.add_theme_color_override("font_color", Color(0.93, 0.83, 0.61))
	titulo.add_theme_font_size_override("font_size", 17)
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_child(titulo)

	var descripcion := Label.new()
	descripcion.text = mejora.descripcion
	descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	descripcion.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	descripcion.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	descripcion.size_flags_vertical = Control.SIZE_EXPAND_FILL
	descripcion.add_theme_color_override("font_color", Color(0.88, 0.79, 0.69))
	descripcion.add_theme_font_size_override("font_size", 14)
	descripcion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_child(descripcion)

	boton.pressed.connect(_solicitar_mejora.bind(mejora))
	return boton


func _solicitar_mejora(mejora: MejoraConfig) -> void:
	if director == null or _recompensa_elegida:
		return
	director.seleccionar_mejora(mejora.id)


func _al_seleccionar_mejora(mejora: MejoraConfig) -> void:
	_recompensa_elegida = true
	_contenedor_recompensas.hide()
	lbl_titulo.text = "MEJORA SELECCIONADA"
	lbl_detalle.text = "%s se aplicará en el siguiente combate." % mejora.nombre


func _limpiar_tarjetas_recompensa() -> void:
	for tarjeta in _contenedor_recompensas.get_children():
		tarjeta.queue_free()


func _actualizar_puntaje(actual: int) -> void:
	lbl_puntaje.text = "PUNTAJE  %06d" % actual


func _actualizar_vidas(actuales: int) -> void:
	lbl_vidas.text = "VIDAS  %d" % actuales


func _actualizar_oleada(indice: int, total: int, nombre: String, es_jefe: bool) -> void:
	var camara: String = NOMBRES_CAMARAS[mini(indice - 1, NOMBRES_CAMARAS.size() - 1)]
	var etiqueta := "JEFE" if es_jefe else "SALA"
	var detalle := nombre.to_upper() if es_jefe else camara.to_upper()
	lbl_oleada.text = "%s  %02d / %02d  ·  %s" % [etiqueta, indice, total, detalle]


func _actualizar_cuenta_regresiva(segundos: int) -> void:
	if estado_actual == DirectorCampana.Estado.INTERMISION:
		lbl_detalle.text = "El siguiente portal se abre en %d…" % segundos


func _aplicar_estilo() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.035, 0.025, 0.03, 0.94)
	panel.border_color = Color(0.50, 0.31, 0.17, 0.9)
	panel.set_border_width_all(1)
	panel.set_border_width(SIDE_BOTTOM, 3)
	panel.set_corner_radius_all(3)
	panel.set_content_margin_all(34)
	$Overlay/Centro/Panel.add_theme_stylebox_override("panel", panel)
	lbl_sello.add_theme_font_override("font", FUENTE_UI)
	lbl_sello.add_theme_font_size_override("font_size", 12)
	lbl_sello.add_theme_color_override("font_color", Color(0.72, 0.52, 0.37))
	lbl_titulo.add_theme_font_override("font", FUENTE_UI)
	lbl_detalle.add_theme_color_override("font_color", Color(0.91, 0.86, 0.77))

	for boton in [btn_principal, btn_menu]:
		boton.add_theme_font_override("font", FUENTE_UI)
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.11, 0.045, 0.043, 0.92)
		normal.border_color = Color(0.48, 0.29, 0.18)
		normal.set_border_width_all(1)
		normal.set_border_width(SIDE_BOTTOM, 2)
		normal.set_corner_radius_all(2)
		normal.set_content_margin_all(10)
		var encima := normal.duplicate() as StyleBoxFlat
		encima.bg_color = Color(0.22, 0.075, 0.045, 0.94)
		encima.border_color = Color(0.78, 0.53, 0.31)
		boton.add_theme_stylebox_override("normal", normal)
		boton.add_theme_stylebox_override("hover", encima)
		boton.add_theme_stylebox_override("focus", encima)
		boton.add_theme_stylebox_override("pressed", normal)
		boton.add_theme_color_override("font_color", Color(0.91, 0.78, 0.60))
		boton.add_theme_color_override("font_hover_color", Color(0.98, 0.88, 0.70))
		boton.add_theme_color_override("font_focus_color", Color(0.98, 0.88, 0.70))


func _actualizar_tiempo(segundos: int) -> void:
	var minutos := floori(float(segundos) / 60.0)
	var resto := segundos % 60
	lbl_tiempo.text = "TIEMPO  %02d:%02d" % [minutos, resto]


func _mostrar_resultado(victoria: bool, puntaje: int) -> void:
	var segundos := floori(director.tiempo_transcurrido) if director != null else 0
	var minutos := floori(float(segundos) / 60.0)
	var resto := segundos % 60
	var indice := director.indice_oleada if director != null else 0
	var total := director.oleadas.size() if director != null else 0
	if victoria:
		lbl_detalle.text = "EL ASEDIADOR HA CAÍDO\n\nPUNTAJE   %06d\nRECORRIDO   %02d / %02d\nDURACIÓN   %02d:%02d" % [
			puntaje, total, total, minutos, resto
		]
	else:
		var sala := ""
		if director != null and indice >= 0 and indice < director.oleadas.size():
			sala = "\n" + director.oleadas[indice].nombre.to_upper()
		lbl_detalle.text = "LA ARENA TE HA VENCIDO%s\n\nPUNTAJE   %06d\nTRAMO   %02d / %02d\nDURACIÓN   %02d:%02d" % [
			sala, puntaje, indice + 1, total, minutos, resto
		]
	btn_principal.grab_focus()


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
