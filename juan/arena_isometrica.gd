extends Node2D

const TILE_GRAFICO = preload("res://assets/arena_isometrica/suelos_hades/tiles_piso.png")
const RUINA_CIRCULAR = preload("res://assets/arena_isometrica/ruinas/01.png")
const RUINA_PILAR = preload("res://assets/arena_isometrica/ruinas/09.png")
const RUINAS = [
	preload("res://assets/arena_isometrica/ruinas_completo/02.png"),
	preload("res://assets/arena_isometrica/ruinas_completo/03.png"),
	preload("res://assets/arena_isometrica/ruinas_completo/06.png"),
	preload("res://assets/arena_isometrica/ruinas_completo/08.png"),
	preload("res://assets/arena_isometrica/ruinas_completo/10.png"),
	preload("res://assets/arena_isometrica/ruinas_completo/12.png"),
	preload("res://assets/arena_isometrica/ruinas_completo/14.png"),
	preload("res://assets/arena_isometrica/ruinas_completo/16.png"),
	preload("res://assets/arena_isometrica/ruinas_completo/19.png"),
]
const PORTAL_TINTA = preload("res://assets/arena_isometrica/tinta/Tile Set/Doors/portal 1.png")
const BRASERO_TINTA = preload("res://assets/arena_isometrica/tinta/Tile Set/Objects/Fire Shrine.png")
const PILAR_BASE_TINTA = preload("res://assets/arena_isometrica/tinta/Tile Set/Pillar/Base.png")
const PILAR_MEDIO_TINTA = preload("res://assets/arena_isometrica/tinta/Tile Set/Pillar/mid.png")
const RESTOS_TINTA = preload("res://assets/arena_isometrica/tinta/Tile Set/Objects/Remains/Remains 1.png")
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
var _vidas: Label
var _zona: Label
var _oleada: Label
var _integridad: ProgressBar
var _luz_nucleo: PointLight2D
var _aro_nucleo: Node2D
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
		_luz_nucleo.energy = 2.5 + sin(Time.get_ticks_msec() / 1000.0 * 1.6) * 0.2
	if is_instance_valid(_aro_nucleo):
		_aro_nucleo.rotation += delta * 0.08
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
	sombra.color = Color(0.80, 0.74, 0.66)
	add_child(sombra)
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.055, 0.035, 0.065)
	entorno.glow_enabled = true
	entorno.glow_intensity = 0.38
	var mundo := WorldEnvironment.new()
	mundo.environment = entorno
	add_child(mundo)
	_textura_luz = _crear_textura_luz()


func _crear_suelo() -> void:
	var conjunto := TileSet.new()
	conjunto.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	conjunto.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	conjunto.tile_size = Vector2i(256, 128)
	_suelo = TileMapLayer.new()
	_suelo.name = "SueloIsometrico"
	_suelo.tile_set = conjunto
	_suelo.y_sort_enabled = true
	_suelo.z_index = -5
	add_child(_suelo)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = TILE_GRAFICO
	atlas.texture_region_size = Vector2i(256, 128)
	for x in 5:
		atlas.create_tile(Vector2i(x, 0))
	conjunto.add_source(atlas, 0)
	_pintar_sala()


func _pintar_sala() -> void:
	for x in range(-10, 11):
		for y in range(-10, 11):
			if abs(x) + abs(y) > 10:
				continue
			var mezcla := posmod(x * 31 + y * 17 + x * y * 7 + _indice_sala * 11, 100)
			var variante := 0
			if mezcla >= 76 and mezcla < 88:
				variante = 1
			elif mezcla >= 88 and mezcla < 96:
				variante = 2
			elif mezcla >= 96:
				variante = 3 if mezcla < 99 else 4
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
	base.polygon = _poligono_elipse(122.0, 56.0, 12)
	base.color = Color(0.12, 0.095, 0.09, 0.78)
	plataforma.add_child(base)
	var aro := Line2D.new()
	aro.points = _puntos_cerrados(_poligono_elipse(114.0, 50.0, 48))
	aro.width = 4.0
	aro.default_color = Color(0.54, 0.30, 0.19, 0.8)
	plataforma.add_child(aro)
	var aro_interno := Line2D.new()
	aro_interno.points = _puntos_cerrados(_poligono_elipse(88.0, 37.0, 48))
	aro_interno.width = 2.0
	aro_interno.default_color = Color(0.67, 0.39, 0.23, 0.75)
	plataforma.add_child(aro_interno)
	var interior := Polygon2D.new()
	interior.polygon = _poligono_elipse(65.0, 25.0, 48)
	interior.color = Color(0.10, 0.055, 0.05, 0.82)
	plataforma.add_child(interior)
	var pulso := Line2D.new()
	pulso.points = _puntos_cerrados(_poligono_elipse(43.0, 16.0, 40))
	pulso.width = 1.0
	pulso.default_color = Color(0.82, 0.42, 0.20, 0.65)
	plataforma.add_child(pulso)
	_aro_nucleo = Node2D.new()
	_aro_nucleo.name = "MarcasDelNucleo"
	plataforma.add_child(_aro_nucleo)
	for indice in 8:
		var marca := Line2D.new()
		marca.points = PackedVector2Array([Vector2(-5, -3), Vector2(0, -8), Vector2(5, -3)])
		marca.position = Vector2(cos(TAU * indice / 8.0) * 99.0, sin(TAU * indice / 8.0) * 43.0)
		marca.rotation = TAU * indice / 8.0
		marca.width = 2.0
		marca.default_color = Color(0.72, 0.46, 0.27, 0.82)
		_aro_nucleo.add_child(marca)
	_luz_nucleo = _crear_luz(Vector2.ZERO, Color(1.0, 0.24, 0.12), 1.15)
	_luz_nucleo.texture_scale = 1.15
	_luz_nucleo.z_index = 1
	plataforma.add_child(_luz_nucleo)


func _crear_ruinas() -> void:
	var circulo := Sprite2D.new()
	circulo.name = "PlataformaAntigua"
	circulo.texture = RUINA_CIRCULAR
	circulo.position = Vector2(0, 6)
	circulo.scale = Vector2(0.82, 0.82)
	circulo.modulate = Color(0.72, 0.67, 0.59, 0.88)
	circulo.z_index = -3
	_entidades.add_child(circulo)

	var posiciones_ruinas := [
		Vector2(-660, -235), Vector2(-455, -385), Vector2(-180, -470),
		Vector2(255, -445), Vector2(585, -310), Vector2(700, -35),
		Vector2(555, 290), Vector2(215, 435), Vector2(-210, 448),
		Vector2(-580, 290), Vector2(-720, 25),
	]
	for indice in posiciones_ruinas.size():
		var ruina := Sprite2D.new()
		ruina.texture = RUINAS[indice % RUINAS.size()]
		ruina.position = posiciones_ruinas[indice]
		ruina.scale = Vector2(0.64, 0.64) if indice % 3 == 0 else Vector2(0.52, 0.52)
		ruina.flip_h = indice % 2 == 1
		ruina.modulate = Color(0.82, 0.73, 0.63, 0.92)
		ruina.z_index = -1
		_entidades.add_child(ruina)

	var grieta_izquierda := Sprite2D.new()
	grieta_izquierda.texture = GRIETA_ROJA
	grieta_izquierda.position = Vector2(-690, 80)
	grieta_izquierda.scale = Vector2(0.58, 0.58)
	grieta_izquierda.modulate = Color(0.75, 0.45, 0.34, 0.7)
	grieta_izquierda.z_index = -3
	_entidades.add_child(grieta_izquierda)

	var grieta_derecha := Sprite2D.new()
	grieta_derecha.texture = GRIETA_ROJA
	grieta_derecha.position = Vector2(670, -95)
	grieta_derecha.scale = Vector2(0.52, 0.52)
	grieta_derecha.modulate = Color(0.72, 0.43, 0.35, 0.62)
	grieta_derecha.z_index = -3
	_entidades.add_child(grieta_derecha)

	var altar := Sprite2D.new()
	altar.name = "MarcaAntigua"
	altar.texture = ALTAR_TINTA
	altar.position = Vector2(-435, -230)
	altar.scale = Vector2(0.34, 0.34)
	altar.modulate = Color(0.72, 0.64, 0.50, 0.38)
	altar.z_index = -2
	_entidades.add_child(altar)

	var restos := Sprite2D.new()
	restos.name = "RestosAntiguos"
	restos.texture = RESTOS_TINTA
	restos.position = Vector2(460, 175)
	restos.scale = Vector2(0.50, 0.50)
	restos.modulate = Color(0.80, 0.72, 0.60, 0.78)
	restos.z_index = -1
	_entidades.add_child(restos)


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
	var energia := Polygon2D.new()
	energia.position = Vector2(0, -105)
	energia.polygon = PackedVector2Array([Vector2(-48, 34), Vector2(-48, -28), Vector2(-24, -63), Vector2(0, -78), Vector2(24, -63), Vector2(48, -28), Vector2(48, 34)])
	energia.color = Color(0.48, 0.09, 0.055, 0.84)
	puerta.add_child(energia)
	var portal := Sprite2D.new()
	portal.name = "ArcoDePiedra"
	portal.texture = PORTAL_TINTA
	portal.position = Vector2(0, -88)
	portal.scale = Vector2(0.78, 0.78)
	portal.modulate = Color(0.86, 0.70, 0.52)
	portal.z_index = 2
	puerta.add_child(portal)
	var luz_nucleo := _crear_luz(Vector2(0, -105), Color(1.0, 0.18, 0.06), 1.5)
	luz_nucleo.texture_scale = 1.45
	puerta.add_child(luz_nucleo)
	_entidades.add_child(puerta)


func _crear_pilares_y_braseros() -> void:
	var posiciones := [Vector2(-370, -195), Vector2(345, -205), Vector2(-330, 190), Vector2(390, 165)]
	for indice in posiciones.size():
		_crear_pilar(posiciones[indice], Color(0.62, 0.90, 0.34) if indice % 2 == 0 else Color(1.0, 0.46, 0.20))
		_crear_brasero(posiciones[indice] + Vector2(0, 72), Color(1.0, 0.48, 0.20))


func _crear_pilar(posicion: Vector2, color_nucleo: Color) -> void:
	var pilar := StaticBody2D.new()
	pilar.name = "PilarDeCobertura"
	pilar.position = posicion
	pilar.collision_layer = 1
	pilar.collision_mask = 1
	var colision := CollisionShape2D.new()
	colision.name = "ColisionBase"
	colision.debug_color = Color(0.2, 1.0, 0.35, 1.0)
	var forma := RectangleShape2D.new()
	forma.size = Vector2(60.0, 32.0)
	colision.shape = forma
	pilar.add_child(colision)
	var base_visual := Sprite2D.new()
	base_visual.texture = PILAR_BASE_TINTA
	base_visual.position = Vector2(0, 0)
	base_visual.scale = Vector2(0.54, 0.54)
	base_visual.modulate = Color(0.85, 0.73, 0.58)
	pilar.add_child(base_visual)
	var columna := Sprite2D.new()
	columna.texture = PILAR_MEDIO_TINTA
	columna.position = Vector2(0, -47)
	columna.scale = Vector2(0.50, 0.50)
	columna.modulate = Color(0.79, 0.67, 0.54)
	pilar.add_child(columna)
	var piedra := Sprite2D.new()
	piedra.texture = RUINA_PILAR
	piedra.position = Vector2(0, -34)
	piedra.scale = Vector2(0.47, 0.47)
	piedra.modulate = Color(0.72, 0.68, 0.60, 0.88)
	piedra.z_index = 1
	pilar.add_child(piedra)
	var nucleo := Polygon2D.new()
	nucleo.position = Vector2(0, -70)
	nucleo.polygon = _poligono_regular(7.0, 8)
	nucleo.color = color_nucleo
	pilar.add_child(nucleo)
	var luz := _crear_luz(Vector2(0, -70), color_nucleo, 0.65)
	luz.z_index = 2
	pilar.add_child(luz)
	_entidades.add_child(pilar)


func _crear_brasero(posicion: Vector2, color_fuego: Color) -> void:
	var brasero := Node2D.new()
	brasero.position = posicion
	var estatua := Sprite2D.new()
	estatua.texture = BRASERO_TINTA
	estatua.position = Vector2(0, -10)
	estatua.scale = Vector2(0.42, 0.42)
	estatua.modulate = Color(0.94, 0.64, 0.37)
	brasero.add_child(estatua)
	var llama := Polygon2D.new()
	llama.position.y = -40
	llama.polygon = PackedVector2Array([Vector2(-6, 4), Vector2(-5, -6), Vector2(0, -15), Vector2(4, -4), Vector2(7, 4), Vector2(0, 8)])
	llama.color = color_fuego
	brasero.add_child(llama)
	var luz := _crear_luz(Vector2.ZERO, color_fuego, 0.8)
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
	_director.vidas_cambiadas.connect(_actualizar_vidas)
	_jugador.connect("murio", Callable(self, "_al_morir_jugador"))
	var interfaz := UI_CAMPANA.instantiate()
	interfaz.set("mostrar_hud", false)
	add_child(interfaz)
	_crear_hud()
	_director.comenzar_campana()

func _al_morir_jugador() -> void:
	if _director == null or not is_instance_valid(_jugador):
		return

	_director.recibir_impacto()

	if _director.vidas > 0:
		_jugador.call("reaparecer")

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
	var enemigo: CharacterBody2D

	if _configuracion.escena_enemigo != null:
		enemigo = _configuracion.escena_enemigo.instantiate() as CharacterBody2D

	if enemigo == null or not enemigo.has_method("configurar"):
		push_error(
			"Escena de enemigo inválida en la configuración: "
			+ _configuracion.nombre
		)

		if is_instance_valid(enemigo):
			enemigo.free()

		enemigo = CharacterBody2D.new()
		enemigo.set_script(SCRIPT_ENEMIGO)

	enemigo.name = "Amenaza_%02d" % get_tree().get_nodes_in_group("enemigos").size()
	enemigo.call(
		"configurar",
		_configuracion.rapidez_formacion,
		_configuracion.puntos_por_enemigo,
		_configuracion.es_jefe
	)

	var borde := randi_range(0, 3)
	match borde:
		0:
			enemigo.position = Vector2(randf_range(-300, 300), -285)
		1:
			enemigo.position = Vector2(randf_range(-300, 300), 285)
		2:
			enemigo.position = Vector2(-500, randf_range(-250, 250))
		_:
			enemigo.position = Vector2(500, randf_range(-250, 250))

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
	var oro := Color(0.91, 0.78, 0.58)
	_crear_texto(capa, "EL INQUIETO", Rect2(30, 20, 240, 30), 19, Color(0.97, 0.87, 0.68))
	_zona = _crear_texto(capa, "ATRIO DE LAS CENIZAS", Rect2(31, 51, 340, 22), 10, Color(0.80, 0.64, 0.47))
	_oleada = _crear_texto(capa, "OLEADA  01 / 06", Rect2(495, 24, 290, 28), 17, oro)
	_oleada.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_puntaje = _crear_texto(capa, "000000  ·  00:00", Rect2(980, 22, 270, 24), 13, oro)
	_puntaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_amenazas = _crear_texto(capa, "AMENAZAS  00", Rect2(1020, 49, 230, 20), 10, Color(0.78, 0.77, 0.62))
	_amenazas.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_vidas = _crear_texto(capa, "VIDAS  %02d" % _director.vidas, Rect2(1020, 72, 230, 20), 10, Color(0.85, 0.74, 0.60))
	_vidas.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_crear_texto(capa, "INTEGRIDAD", Rect2(1032, 662, 212, 17), 9, Color(0.85, 0.74, 0.60))
	_integridad = ProgressBar.new()
	_integridad.position = Vector2(1032, 682)
	_integridad.size = Vector2(212, 8)
	_integridad.max_value = 100.0
	_integridad.value = 100.0
	_integridad.show_percentage = false
	var fondo_barra := StyleBoxFlat.new()
	fondo_barra.bg_color = Color(0.09, 0.055, 0.05, 0.9)
	_integridad.add_theme_stylebox_override("background", fondo_barra)
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = Color(0.78, 0.26, 0.15)
	_integridad.add_theme_stylebox_override("fill", relleno)
	capa.add_child(_integridad)


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
	luz.texture_scale = 2.6
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


func _poligono_elipse(radio_x: float, radio_y: float, lados: int) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for indice in lados:
		var angulo := TAU * float(indice) / lados
		puntos.append(Vector2(cos(angulo) * radio_x, sin(angulo) * radio_y))
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
		_puntaje.text = "%06d  ·  %02d:%02d" % [_director.puntaje, floori(float(segundos) / 60.0), segundos % 60]
	if is_instance_valid(_amenazas):
		var enemigos_activos := get_tree().get_nodes_in_group("enemigos").size()
		_amenazas.text = "ACTIVOS %02d · POR LLEGAR %02d" % [
			enemigos_activos,
			_enemigos_restantes
		]
	if is_instance_valid(_integridad) and is_instance_valid(_jugador):
		_integridad.value = _jugador.get("integridad")


func _actualizar_integridad(actual: float) -> void:
	if is_instance_valid(_integridad):
		_integridad.value = actual


func _actualizar_vidas(actuales: int) -> void:
	if is_instance_valid(_vidas):
		_vidas.text = "VIDAS  %02d" % actuales
