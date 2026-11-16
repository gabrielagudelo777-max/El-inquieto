extends Node2D

const TILE_GRAFICO = preload("res://assets/arena_isometrica_tiles.svg")
const RUINA_CIRCULAR = preload("res://assets/arena_isometrica/ruinas/01.png")
const RUINA_MURO = preload("res://assets/arena_isometrica/ruinas/04.png")
const RUINA_PILAR = preload("res://assets/arena_isometrica/ruinas/09.png")
const GRIETA_ROJA = preload("res://assets/arena_isometrica/grietas/Dark Fantasy Isometric Tiles (CC-BY 4.0 - Of Far Different Nature)/OFDN Isometric Tile 09.png")
const ALTAR_TINTA = preload("res://assets/arena_isometrica/tinta/Tile Set/Altar/Altar 1.png")
const SCRIPT_JUGADOR = preload("res://juan/jugador_isometrico.gd")
const SCRIPT_ENEMIGO = preload("res://juan/enemigo_isometrico.gd")
const SCRIPT_DIRECTOR = preload("res://juan/director_campana.gd")
const UI_CAMPANA = preload("res://juan/ui_campana.tscn")
const FUENTE = preload("res://assets/fonts/CinzelDecorative-Regular.ttf")
const OLEADAS := [
	"res://juan/oleadas/oleada_01.tres",
	"res://juan/oleadas/oleada_02.tres",
	"res://juan/oleadas/oleada_03.tres",
	"res://juan/oleadas/oleada_04.tres",
	"res://juan/oleadas/oleada_05.tres",
	"res://juan/oleadas/oleada_06_jefe.tres",
]
const SALAS := ["ATRIO DE LAS CENIZAS", "GALERÍA CARMESÍ", "FOSO DEL ECLIPSE", "SANTUARIO DE BRASA", "PASAJE DE LOS ECOS", "SALA DEL VIGÍA"]

var _suelo: TileMapLayer
var _entidades: Node2D
var _jugador: CharacterBody2D
var _director: DirectorCampana
var _configuracion: OleadaConfig
var _enemigos_restantes := 0
var _reloj_aparicion := 0.0
var _indice_sala := 0
var _puntaje: Label
var _amenazas: Label
var _zona: Label
var _oleada: Label
var _integridad: ProgressBar
var _luz_nucleo: PointLight2D
var _textura_luz: Texture2D


func _ready() -> void:
	_crear_ambiente()
	_crear_suelo()
	_crear_entorno()
	_crear_murossala()
	_crear_ruinas()
	_crear_nucleo()
	_crear_portal()
	_crear_pilares_y_braseros()
	_crear_esporas()
	_crear_jugador()
	_crear_director_y_hud()
	_crear_camara()
	_actualizar_hud()


func _process(delta: float) -> void:
	if is_instance_valid(_luz_nucleo):
		_luz_nucleo.energy = 4.0 + sin(Time.get_ticks_msec() / 1000.0 * 2.0) * 0.35
	if _director != null and _director.estado == DirectorCampana.Estado.COMBATE and _enemigos_restantes > 0:
		_reloj_aparicion -= delta
		if _reloj_aparicion <= 0.0:
			_aparecer_enemigo()
			_enemigos_restantes -= 1
			_reloj_aparicion = _configuracion.intervalo_aparicion
	_actualizar_hud()


func _crear_ambiente() -> void:
	var fondo := Polygon2D.new()
	fondo.polygon = PackedVector2Array([Vector2(-1800, -1000), Vector2(1800, -1000), Vector2(1800, 1000), Vector2(-1800, 1000)])
	fondo.color = Color(0.055, 0.035, 0.065)
	fondo.z_index = -20
	add_child(fondo)
	var sombra := CanvasModulate.new()
	sombra.color = Color(0.55, 0.60, 0.54)
	add_child(sombra)
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.055, 0.035, 0.065)
	entorno.glow_enabled = true
	entorno.glow_intensity = 0.8
	var mundo := WorldEnvironment.new()
	mundo.environment = entorno
	add_child(mundo)
	_textura_luz = _crear_textura_luz()


func _crear_suelo() -> void:
	var conjunto := TileSet.new()
	conjunto.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	conjunto.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	conjunto.tile_size = Vector2i(128, 64)
	_suelo = TileMapLayer.new()
	_suelo.name = "SueloIsometrico"
	_suelo.tile_set = conjunto
	_suelo.y_sort_enabled = true
	_suelo.z_index = -5
	add_child(_suelo)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = TILE_GRAFICO
	atlas.texture_region_size = Vector2i(128, 64)
	for x in 4:
		atlas.create_tile(Vector2i(x, 0))
	conjunto.add_source(atlas, 0)
	_pintar_sala()


func _pintar_sala() -> void:
	for x in range(-18, 18):
		for y in range(-18, 18):
			var variante := posmod(x * 3 + y * 5 + _indice_sala, 4)
			_suelo.set_cell(Vector2i(x, y), 0, Vector2i(variante, 0))


func _crear_entorno() -> void:
	_entidades = Node2D.new()
	_entidades.name = "EntidadesYObstaculos"
	_entidades.y_sort_enabled = true
	_entidades.add_to_group("contenedor_entidades")
	add_child(_entidades)


func _crear_nucleo() -> void:
	var plataforma := Node2D.new()
	plataforma.name = "NucleoDeContencion"
	_entidades.add_child(plataforma)
	var base := Polygon2D.new()
	base.polygon = _poligono_regular(150.0, 8)
	base.color = Color(0.11, 0.075, 0.085)
	plataforma.add_child(base)
	var aro := Line2D.new()
	aro.points = _puntos_cerrados(_poligono_regular(132.0, 8))
	aro.width = 12.0
	aro.default_color = Color(1.0, 0.20, 0.08)
	plataforma.add_child(aro)
	var aro_interno := Line2D.new()
	aro_interno.points = _puntos_cerrados(_poligono_regular(92.0, 8))
	aro_interno.width = 5.0
	aro_interno.default_color = Color(1.0, 0.55, 0.15)
	plataforma.add_child(aro_interno)
	_luz_nucleo = _crear_luz(Vector2.ZERO, Color(1.0, 0.12, 0.055), 4.8)
	_luz_nucleo.z_index = 1
	plataforma.add_child(_luz_nucleo)
	for indice in 8:
		var runa := Polygon2D.new()
		runa.polygon = PackedVector2Array([Vector2(-5, -11), Vector2(5, -11), Vector2(10, 0), Vector2(-10, 0)])
		runa.position = Vector2(cos(TAU * indice / 8.0), sin(TAU * indice / 8.0)) * 110.0
		runa.rotation = TAU * indice / 8.0
		runa.color = Color(1.0, 0.53, 0.15)
		plataforma.add_child(runa)


func _crear_ruinas() -> void:
	var circulo := Sprite2D.new()
	circulo.name = "PlataformaAntigua"
	circulo.texture = RUINA_CIRCULAR
	circulo.position = Vector2(0, 6)
	circulo.scale = Vector2(1.30, 1.30)
	circulo.z_index = -2
	_entidades.add_child(circulo)

	for lado in [-1, 1]:
		var muro := Sprite2D.new()
		muro.texture = RUINA_MURO
		muro.position = Vector2(550.0 * lado, -250)
		muro.flip_h = lado < 0
		muro.scale = Vector2(1.15, 1.15)
		muro.z_index = -1
		_entidades.add_child(muro)

	var grieta_izquierda := Sprite2D.new()
	grieta_izquierda.texture = GRIETA_ROJA
	grieta_izquierda.position = Vector2(-620, 105)
	grieta_izquierda.scale = Vector2(0.78, 0.78)
	grieta_izquierda.modulate = Color(0.82, 0.52, 0.48, 0.82)
	grieta_izquierda.z_index = -3
	_entidades.add_child(grieta_izquierda)

	var grieta_derecha := Sprite2D.new()
	grieta_derecha.texture = GRIETA_ROJA
	grieta_derecha.position = Vector2(620, -85)
	grieta_derecha.scale = Vector2(0.68, 0.68)
	grieta_derecha.modulate = Color(0.72, 0.45, 0.42, 0.72)
	grieta_derecha.z_index = -3
	_entidades.add_child(grieta_derecha)

	var altar := Sprite2D.new()
	altar.name = "MarcaAntigua"
	altar.texture = ALTAR_TINTA
	altar.position = Vector2(-470, -170)
	altar.scale = Vector2(0.48, 0.48)
	altar.modulate = Color(0.72, 0.82, 0.67, 0.42)
	altar.z_index = -2
	_entidades.add_child(altar)


func _crear_murossala() -> void:
	var contorno := _puntos_cerrados(PackedVector2Array([
		Vector2(0, -635), Vector2(635, -318), Vector2(1270, 0),
		Vector2(635, 318), Vector2(0, 635), Vector2(-635, 318),
		Vector2(-1270, 0), Vector2(-635, -318)
	]))
	var muro := Line2D.new()
	muro.name = "MuroPerimetral"
	muro.points = contorno
	muro.width = 48.0
	muro.default_color = Color(0.10, 0.065, 0.075)
	muro.z_index = -4
	_entidades.add_child(muro)
	var moldura := Line2D.new()
	moldura.points = contorno
	moldura.width = 5.0
	moldura.default_color = Color(0.66, 0.34, 0.15)
	moldura.z_index = -3
	_entidades.add_child(moldura)
	var colision_muro := CollisionPolygon2D.new()
	colision_muro.polygon = contorno
	colision_muro.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	var cuerpo_muro := StaticBody2D.new()
	cuerpo_muro.name = "ColisionMuroPerimetral"
	cuerpo_muro.add_child(colision_muro)
	_entidades.add_child(cuerpo_muro)


func _crear_portal() -> void:
	var puerta := StaticBody2D.new()
	puerta.name = "CompuertaDeContencion"
	puerta.position = Vector2(0, -310)
	puerta.collision_layer = 1
	puerta.collision_mask = 1
	var base := CollisionPolygon2D.new()
	base.polygon = PackedVector2Array([Vector2(-190, 0), Vector2(0, -48), Vector2(190, 0), Vector2(0, 48)])
	puerta.add_child(base)
	var muro := Polygon2D.new()
	muro.polygon = PackedVector2Array([Vector2(-235, 0), Vector2(-190, -110), Vector2(-115, -158), Vector2(0, -190), Vector2(115, -158), Vector2(190, -110), Vector2(235, 0), Vector2(0, 56)])
	muro.color = Color(0.12, 0.075, 0.085)
	puerta.add_child(muro)
	var marco := Line2D.new()
	marco.points = PackedVector2Array([Vector2(-90, -40), Vector2(-90, -112), Vector2(0, -168), Vector2(90, -112), Vector2(90, -40)])
	marco.width = 15.0
	marco.default_color = Color(0.73, 0.39, 0.17)
	puerta.add_child(marco)
	var hexagono := Line2D.new()
	hexagono.points = _puntos_cerrados(_poligono_regular(67.0, 6))
	hexagono.position = Vector2(0, -92)
	hexagono.width = 12.0
	hexagono.default_color = Color(1.0, 0.14, 0.055)
	puerta.add_child(hexagono)
	_entidades.add_child(puerta)
	var luz_puerta := _crear_luz(Vector2(0, -410), Color(1.0, 0.12, 0.045), 4.0)
	add_child(luz_puerta)


func _crear_pilares_y_braseros() -> void:
	var posiciones := [Vector2(-315, -145), Vector2(315, -145), Vector2(-315, 145), Vector2(315, 145)]
	for indice in posiciones.size():
		_crear_pilar(posiciones[indice], Color(0.27, 1.0, 0.15) if indice % 2 == 0 else Color(1.0, 0.32, 0.08))
		_crear_brasero(posiciones[indice] + Vector2(0, 72), Color(1.0, 0.36, 0.08) if indice % 2 == 0 else Color(0.30, 0.95, 0.20))


func _crear_pilar(posicion: Vector2, color_nucleo: Color) -> void:
	var pilar := StaticBody2D.new()
	pilar.name = "PilarDeCobertura"
	pilar.position = posicion
	pilar.collision_layer = 1
	pilar.collision_mask = 1
	var base := CollisionPolygon2D.new()
	base.polygon = PackedVector2Array([Vector2(-30, 0), Vector2(0, -16), Vector2(30, 0), Vector2(0, 16)])
	pilar.add_child(base)
	var frente := Polygon2D.new()
	frente.position.y = -40
	frente.polygon = PackedVector2Array([Vector2(-36, -35), Vector2(0, -17), Vector2(0, 18), Vector2(-36, 0)])
	frente.color = Color(0.18, 0.12, 0.13)
	pilar.add_child(frente)
	var costado := Polygon2D.new()
	costado.position.y = -40
	costado.polygon = PackedVector2Array([Vector2(0, -17), Vector2(36, -35), Vector2(36, 0), Vector2(0, 18)])
	costado.color = Color(0.10, 0.085, 0.10)
	pilar.add_child(costado)
	var cima := Polygon2D.new()
	cima.position.y = -58
	cima.polygon = PackedVector2Array([Vector2(-36, 0), Vector2(0, -19), Vector2(36, 0), Vector2(0, 19)])
	cima.color = Color(0.34, 0.24, 0.19)
	pilar.add_child(cima)
	var nucleo := Polygon2D.new()
	nucleo.position = Vector2(0, -54)
	nucleo.polygon = _poligono_regular(11.0, 8)
	nucleo.color = color_nucleo
	pilar.add_child(nucleo)
	var luz := _crear_luz(Vector2(0, -54), color_nucleo, 1.5)
	luz.z_index = 2
	pilar.add_child(luz)
	var piedra := Sprite2D.new()
	piedra.texture = RUINA_PILAR
	piedra.position = Vector2(0, -28)
	piedra.scale = Vector2(0.72, 0.72)
	piedra.z_index = -1
	pilar.add_child(piedra)
	_entidades.add_child(pilar)


func _crear_brasero(posicion: Vector2, color_fuego: Color) -> void:
	var brasero := Node2D.new()
	brasero.position = posicion
	var copa := Polygon2D.new()
	copa.polygon = PackedVector2Array([Vector2(-18, -7), Vector2(0, -16), Vector2(18, -7), Vector2(12, 8), Vector2(-12, 8)])
	copa.color = Color(0.61, 0.32, 0.14)
	brasero.add_child(copa)
	var llama := Polygon2D.new()
	llama.position.y = -20
	llama.polygon = PackedVector2Array([Vector2(-10, 7), Vector2(-8, -7), Vector2(0, -21), Vector2(4, -6), Vector2(11, 5), Vector2(0, 12)])
	llama.color = color_fuego
	brasero.add_child(llama)
	var luz := _crear_luz(Vector2.ZERO, color_fuego, 1.7)
	brasero.add_child(luz)
	_entidades.add_child(brasero)


func _crear_jugador() -> void:
	_jugador = CharacterBody2D.new()
	_jugador.name = "VigiaCarmesi"
	_jugador.set_script(SCRIPT_JUGADOR)
	_jugador.position = Vector2(0, 210)
	_jugador.connect("integridad_cambiada", Callable(self, "_actualizar_integridad"))
	_entidades.add_child(_jugador)


func _crear_director_y_hud() -> void:
	_director = SCRIPT_DIRECTOR.new() as DirectorCampana
	_director.name = "DirectorCampana"
	for ruta in OLEADAS:
		var configuracion := load(ruta) as OleadaConfig
		if configuracion != null:
			_director.oleadas.append(configuracion)
	add_child(_director)
	_director.oleada_iniciada.connect(_iniciar_oleada)
	var interfaz := UI_CAMPANA.instantiate()
	interfaz.set("mostrar_hud", false)
	add_child(interfaz)
	_crear_hud()
	_director.comenzar_campana()


func _iniciar_oleada(indice: int, configuracion: OleadaConfig) -> void:
	_indice_sala = indice - 1
	_configuracion = configuracion
	_enemigos_restantes = configuracion.cantidad_enemigos
	_reloj_aparicion = 0.0
	_pintar_sala()
	if is_instance_valid(_luz_nucleo):
		_luz_nucleo.color = Color(1.0, 0.16, 0.06) if indice < 6 else Color(0.32, 1.0, 0.18)
	if is_instance_valid(_zona):
		_zona.text = "ZONA DE CONTENCIÓN  //  SECTOR %02d · %s" % [indice, SALAS[_indice_sala]]
	if is_instance_valid(_oleada):
		var tipo := "JEFE" if configuracion.es_jefe else "OLEADA"
		_oleada.text = "%s  %02d / %02d" % [tipo, indice, OLEADAS.size()]


func _aparecer_enemigo() -> void:
	var enemigo := CharacterBody2D.new()
	enemigo.name = "Amenaza_%02d" % get_tree().get_nodes_in_group("enemigos").size()
	enemigo.set_script(SCRIPT_ENEMIGO)
	enemigo.call("configurar", _configuracion.rapidez_formacion, _configuracion.puntos_por_enemigo, _configuracion.es_jefe)
	var borde := randi_range(0, 3)
	match borde:
		0: enemigo.position = Vector2(randf_range(-300, 300), -285)
		1: enemigo.position = Vector2(randf_range(-300, 300), 285)
		2: enemigo.position = Vector2(-500, randf_range(-250, 250))
		_: enemigo.position = Vector2(500, randf_range(-250, 250))
	if _configuracion.es_jefe:
		enemigo.scale = Vector2(1.7, 1.7)
	_entidades.add_child(enemigo)


func _crear_camara() -> void:
	var camara := Camera2D.new()
	camara.name = "CamaraIsometrica"
	camara.zoom = Vector2(0.70, 0.70)
	camara.position_smoothing_enabled = true
	camara.position_smoothing_speed = 4.0
	camara.limit_left = -1280
	camara.limit_right = 1280
	camara.limit_top = -640
	camara.limit_bottom = 640
	camara.enabled = true
	_jugador.add_child(camara)


func _crear_hud() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 10
	add_child(capa)
	var fondo := Color(0.055, 0.035, 0.045, 0.91)
	var oro := Color(0.87, 0.66, 0.39)
	var panel_titulo := _crear_panel(capa, Rect2(22, 18, 410, 74), fondo, oro)
	_crear_texto(panel_titulo, "EL INQUIETO", Rect2(16, 7, 370, 34), 23, Color(0.96, 0.84, 0.62))
	_zona = _crear_texto(panel_titulo, "ZONA DE CONTENCIÓN  //  SECTOR 01", Rect2(18, 43, 380, 23), 11, Color(0.84, 0.57, 0.35))
	var panel_oleada := _crear_panel(capa, Rect2(480, 18, 320, 62), fondo, oro)
	_oleada = _crear_texto(panel_oleada, "OLEADA  01 / 06", Rect2(18, 13, 284, 34), 20, Color(1.0, 0.79, 0.48))
	var panel_datos := _crear_panel(capa, Rect2(846, 18, 410, 74), fondo, Color(0.52, 0.70, 0.39))
	_puntaje = _crear_texto(panel_datos, "PUNTAJE 000000  ·  TIEMPO 00:00", Rect2(14, 10, 382, 24), 13, oro)
	_amenazas = _crear_texto(panel_datos, "AMENAZAS 00", Rect2(14, 42, 382, 22), 12, Color(0.59, 0.91, 0.42))
	var panel_controles := _crear_panel(capa, Rect2(22, 628, 620, 66), fondo, oro)
	_crear_texto(panel_controles, "WASD / FLECHAS  MOVER     SHIFT  ESQUIVAR     ESPACIO  DISPARAR", Rect2(15, 18, 590, 28), 11, Color(0.90, 0.80, 0.67))
	var panel_vida := _crear_panel(capa, Rect2(948, 620, 308, 74), fondo, Color(0.20, 0.78, 0.92))
	_crear_texto(panel_vida, "INTEGRIDAD DEL TRAJE", Rect2(15, 5, 275, 22), 11, Color(0.70, 0.89, 0.91))
	_integridad = ProgressBar.new()
	_integridad.position = Vector2(15, 34)
	_integridad.size = Vector2(276, 22)
	_integridad.max_value = 100.0
	_integridad.value = 100.0
	_integridad.show_percentage = false
	var fondo_barra := StyleBoxFlat.new()
	fondo_barra.bg_color = Color(0.045, 0.08, 0.11)
	fondo_barra.set_corner_radius_all(4)
	_integridad.add_theme_stylebox_override("background", fondo_barra)
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = Color(0.12, 0.76, 0.92)
	relleno.set_corner_radius_all(4)
	_integridad.add_theme_stylebox_override("fill", relleno)
	panel_vida.add_child(_integridad)


func _crear_panel(parent: Node, rectangulo: Rect2, color: Color, borde: Color) -> Panel:
	var panel := Panel.new()
	panel.position = rectangulo.position
	panel.size = rectangulo.size
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.border_color = borde
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(8)
	estilo.shadow_color = Color(0.01, 0.005, 0.01, 0.7)
	estilo.shadow_size = 8
	panel.add_theme_stylebox_override("panel", estilo)
	parent.add_child(panel)
	return panel


func _crear_texto(parent: Node, texto: String, rectangulo: Rect2, tamano: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.position = rectangulo.position
	etiqueta.size = rectangulo.size
	etiqueta.add_theme_font_override("font", FUENTE)
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(etiqueta)
	return etiqueta


func _crear_esporas() -> void:
	var textura := _textura_luz
	for color in [Color(0.38, 1.0, 0.24, 0.8), Color(1.0, 0.34, 0.12, 0.75)]:
		var esporas := GPUParticles2D.new()
		esporas.amount = 72
		esporas.lifetime = 7.0
		esporas.preprocess = 5.0
		esporas.position = Vector2.ZERO
		esporas.visibility_rect = Rect2(-1100, -520, 2200, 1040)
		esporas.texture = textura
		var proceso := ParticleProcessMaterial.new()
		proceso.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		proceso.emission_box_extents = Vector3(1450, 700, 0)
		proceso.direction = Vector3(0, -1, 0)
		proceso.spread = 180.0
		proceso.gravity = Vector3(0, -7, 0)
		proceso.initial_velocity_min = 8.0
		proceso.initial_velocity_max = 28.0
		proceso.scale_min = 0.12
		proceso.scale_max = 0.35
		proceso.color = color
		esporas.process_material = proceso
		esporas.z_index = 3
		add_child(esporas)


func _crear_luz(posicion: Vector2, color: Color, energia: float) -> PointLight2D:
	var luz := PointLight2D.new()
	luz.texture = _textura_luz
	luz.texture_scale = 3.4
	luz.color = color
	luz.energy = energia
	luz.position = posicion
	return luz


func _crear_textura_luz() -> Texture2D:
	var gradiente := Gradient.new()
	gradiente.set_color(0, Color.WHITE)
	gradiente.set_color(1, Color(1, 1, 1, 0))
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	textura.width = 96
	textura.height = 96
	return textura


func _poligono_regular(radio: float, lados: int) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for indice in lados:
		var angulo := -PI / 2.0 + TAU * float(indice) / lados
		puntos.append(Vector2(cos(angulo), sin(angulo)) * radio)
	return puntos


func _puntos_cerrados(puntos: PackedVector2Array) -> PackedVector2Array:
	var resultado := puntos.duplicate()
	if not resultado.is_empty():
		resultado.append(resultado[0])
	return resultado


func _actualizar_hud() -> void:
	if _director == null:
		return
	if is_instance_valid(_puntaje):
		var segundos := floori(_director.tiempo_transcurrido)
		_puntaje.text = "PUNTAJE %06d  ·  TIEMPO %02d:%02d" % [_director.puntaje, floori(float(segundos) / 60.0), segundos % 60]
	if is_instance_valid(_amenazas):
		_amenazas.text = "AMENAZAS  %02d" % get_tree().get_nodes_in_group("enemigos").size()
	if is_instance_valid(_integridad) and is_instance_valid(_jugador):
		_integridad.value = _jugador.get("integridad")


func _actualizar_integridad(actual: float) -> void:
	if is_instance_valid(_integridad):
		_integridad.value = actual
