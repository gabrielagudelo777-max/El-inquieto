extends Node3D

const ASTRONAUTA = "res://assets/quaternius_ultimate_space/Astronaut.glb"
const ALIEN = "res://assets/quaternius_modular_scifi/glTF/Aliens/Alien_Scolitex.gltf"
const NEBULOSA = "res://assets/kenney_skyboxes_space/Skyboxes/skybox-space-nebula.png"
const PANEL_HUD = "res://assets/1. Free Hologram Interface Wenrexa/1. Free Hologram Interface Wenrexa/Card X1/Panel Empty Green.png"
const TIPOGRAFIA = "res://assets/fonts/CinzelDecorative-Regular.ttf"
const SCRIPT_JUGADOR = preload("res://juan/jugador_batalla.gd")
const SCRIPT_ALIEN = preload("res://juan/enemigo_batalla.gd")

var _jugador: CharacterBody3D
var _etiqueta_enemigos: Label
var _barra_integridad: ProgressBar
var _etiqueta_mensaje: Label


func _ready() -> void:
	add_to_group("control_arena")
	_crear_entorno()
	_crear_arena()
	_crear_jugador()
	_crear_enemigos()
	_crear_camara()
	_crear_interfaz()


func _process(_delta: float) -> void:
	if is_instance_valid(_etiqueta_enemigos):
		_etiqueta_enemigos.text = "AMENAZAS  %02d" % get_tree().get_nodes_in_group("enemigos").size()
	if is_instance_valid(_barra_integridad) and is_instance_valid(_jugador):
		_barra_integridad.value = float(_jugador.get("integridad"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://escenas/main_menu.tscn")


func mostrar_mensaje(texto: String) -> void:
	if not is_instance_valid(_etiqueta_mensaje):
		return
	_etiqueta_mensaje.text = texto
	_etiqueta_mensaje.visible = true
	var temporizador := get_tree().create_timer(2.2)
	temporizador.timeout.connect(func() -> void:
		if is_instance_valid(_etiqueta_mensaje):
			_etiqueta_mensaje.visible = false
	)


func _crear_entorno() -> void:
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_SKY
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.30, 0.43, 0.58)
	entorno.ambient_light_energy = 0.85
	entorno.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	entorno.glow_enabled = true
	entorno.glow_intensity = 0.45
	var material_cielo := PanoramaSkyMaterial.new()
	material_cielo.panorama = load(NEBULOSA)
	material_cielo.energy_multiplier = 0.72
	var cielo := Sky.new()
	cielo.sky_material = material_cielo
	entorno.sky = cielo
	var cielo_mundo := WorldEnvironment.new()
	cielo_mundo.environment = entorno
	add_child(cielo_mundo)

	var luz_principal := DirectionalLight3D.new()
	luz_principal.rotation_degrees = Vector3(-53.0, -24.0, 0.0)
	luz_principal.light_color = Color(0.70, 0.83, 1.0)
	luz_principal.light_energy = 1.25
	luz_principal.shadow_enabled = true
	add_child(luz_principal)

	var luz_centro := OmniLight3D.new()
	luz_centro.position = Vector3(0.0, 4.2, 0.0)
	luz_centro.light_color = Color(0.12, 0.68, 1.0)
	luz_centro.light_energy = 4.0
	luz_centro.omni_range = 13.0
	add_child(luz_centro)


func _crear_arena() -> void:
	var suelo := StaticBody3D.new()
	suelo.name = "Plataforma"
	var malla_suelo := MeshInstance3D.new()
	var caja_suelo := BoxMesh.new()
	caja_suelo.size = Vector3(20.0, 0.65, 20.0)
	malla_suelo.mesh = caja_suelo
	malla_suelo.position.y = -0.36
	malla_suelo.material_override = _material(Color(0.045, 0.075, 0.12), 0.55)
	suelo.add_child(malla_suelo)
	var colision_suelo := CollisionShape3D.new()
	var forma_suelo := BoxShape3D.new()
	forma_suelo.size = caja_suelo.size
	colision_suelo.shape = forma_suelo
	colision_suelo.position.y = -0.36
	suelo.add_child(colision_suelo)
	add_child(suelo)

	var centro := MeshInstance3D.new()
	var malla_centro := CylinderMesh.new()
	malla_centro.top_radius = 2.35
	malla_centro.bottom_radius = 2.55
	malla_centro.height = 0.12
	centro.mesh = malla_centro
	centro.position.y = 0.02
	centro.material_override = _material(Color(0.075, 0.12, 0.19), 0.72)
	add_child(centro)
	_crear_anillo(2.85, Color(0.08, 0.66, 1.0), 0.055, 0.10)
	_crear_anillo(3.12, Color(0.78, 0.51, 0.23), 0.026, 0.04)

	var material_linea := _material(Color(0.035, 0.48, 0.75), 0.25, true)
	var material_borde := _material(Color(0.12, 0.22, 0.32), 0.62)
	for indice in 4:
		var rotacion := indice * PI * 0.5
		var x := sin(rotacion) * 9.45
		var z := cos(rotacion) * 9.45
		var pared := Vector3(20.0, 0.8, 0.48) if indice % 2 == 0 else Vector3(0.48, 0.8, 20.0)
		_crear_bloque("Muro_%d" % indice, Vector3(x, 0.14, z), pared, material_borde, true)
		var longitud := Vector3(19.0, 0.035, 0.07) if indice % 2 == 0 else Vector3(0.07, 0.035, 19.0)
		_crear_linea(Vector3(x, 0.57, z), longitud, material_linea)

	var material_cubierta := _material(Color(0.095, 0.16, 0.23), 0.7)
	for indice in 6:
		var angulo := TAU * float(indice) / 6.0
		var posicion := Vector3(cos(angulo) * 5.2, 0.46, sin(angulo) * 5.2)
		var obstaculo := Vector3(1.55, 0.92, 0.72) if indice % 2 == 0 else Vector3(0.72, 0.92, 1.55)
		_crear_bloque("Cobertura_%02d" % indice, posicion, obstaculo, material_cubierta, true)
		var luz := MeshInstance3D.new()
		var malla_luz := BoxMesh.new()
		malla_luz.size = Vector3(obstaculo.x * 0.76, 0.035, 0.045) if indice % 2 == 0 else Vector3(0.045, 0.035, obstaculo.z * 0.76)
		luz.mesh = malla_luz
		luz.position = posicion + Vector3(0, 0.49, 0)
		luz.material_override = material_linea
		add_child(luz)

	for indice in 4:
		var angulo := PI * 0.25 + float(indice) * PI * 0.5
		var baliza := OmniLight3D.new()
		baliza.position = Vector3(cos(angulo) * 7.8, 1.6, sin(angulo) * 7.8)
		baliza.light_color = Color(0.08, 0.62, 1.0)
		baliza.light_energy = 2.2
		baliza.omni_range = 5.2
		add_child(baliza)
		_crear_anillo_en(Vector3(cos(angulo) * 7.8, 0.035, sin(angulo) * 7.8), 0.46, Color(0.1, 0.62, 0.96), 0.035)

	var lucesuelo := load("res://assets/quaternius_modular_scifi/glTF/Props/Prop_Light_Floor.gltf") as PackedScene
	if lucesuelo:
		for posicion in [Vector3(-8.2, 0.0, -8.2), Vector3(8.2, 0.0, -8.2), Vector3(-8.2, 0.0, 8.2), Vector3(8.2, 0.0, 8.2)]:
			var pieza := lucesuelo.instantiate()
			pieza.position = posicion
			pieza.scale = Vector3.ONE * 0.72
			add_child(pieza)


func _crear_jugador() -> void:
	_jugador = CharacterBody3D.new()
	_jugador.name = "Astronauta"
	_jugador.position = Vector3(0.0, 0.0, 6.25)
	_jugador.set_script(SCRIPT_JUGADOR)
	var colision := CollisionShape3D.new()
	var capsula := CapsuleShape3D.new()
	capsula.radius = 0.38
	capsula.height = 1.7
	colision.shape = capsula
	colision.position.y = 0.85
	_jugador.add_child(colision)
	var escena_astronauta := load(ASTRONAUTA) as PackedScene
	if escena_astronauta:
		var modelo := escena_astronauta.instantiate()
		modelo.name = "ModeloAstronauta"
		_jugador.add_child(modelo)
		var animacion := modelo.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if animacion and animacion.has_animation("CharacterArmature|Idle_Gun"):
			animacion.play("CharacterArmature|Idle_Gun")
	add_child(_jugador)


func _crear_enemigos() -> void:
	var posiciones := [Vector3(-4.1, 0.0, -5.9), Vector3(0.0, 0.0, -7.2), Vector3(4.1, 0.0, -5.9), Vector3(-6.8, 0.0, 1.0), Vector3(6.8, 0.0, 1.0)]
	var escena_aliens := load(ALIEN) as PackedScene
	for indice in posiciones.size():
		var alien := CharacterBody3D.new()
		alien.name = "Amenaza_%02d" % (indice + 1)
		alien.position = posiciones[indice]
		alien.set_script(SCRIPT_ALIEN)
		var colision := CollisionShape3D.new()
		var capsula := CapsuleShape3D.new()
		capsula.radius = 0.48
		capsula.height = 1.5
		colision.shape = capsula
		colision.position.y = 0.75
		alien.add_child(colision)
		if escena_aliens:
			var modelo := escena_aliens.instantiate()
			modelo.name = "ModeloAlien"
			modelo.scale = Vector3.ONE * 0.55
			alien.add_child(modelo)
		add_child(alien)


func _crear_camara() -> void:
	var camara := Camera3D.new()
	camara.name = "CamaraArena"
	camara.position = Vector3(0.0, 17.5, 19.0)
	camara.projection = Camera3D.PROJECTION_ORTHOGONAL
	camara.size = 23.5
	camara.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
	camara.current = true
	add_child(camara)


func _crear_interfaz() -> void:
	var capa := CanvasLayer.new()
	capa.name = "InterfazArena"
	add_child(capa)
	var textura := load(PANEL_HUD) as Texture2D
	var fuente := load(TIPOGRAFIA) as Font

	var panel_titulo := _crear_panel(capa, Rect2(24, 22, 390, 104), textura)
	_crear_etiqueta(panel_titulo, "EL INQUIETO", Vector2(22, 14), Vector2(345, 34), fuente, 23, Color(0.93, 0.83, 0.61))
	_crear_etiqueta(panel_titulo, "ZONA DE CONTENCIÓN  //  SECTOR 01", Vector2(24, 58), Vector2(340, 22), fuente, 12, Color(0.49, 0.81, 0.94))

	var panel_amenazas := _crear_panel(capa, Rect2(915, 22, 340, 104), textura)
	_crear_etiqueta(panel_amenazas, "LECTURA DE RADAR", Vector2(20, 14), Vector2(295, 24), fuente, 14, Color(0.70, 0.82, 0.90))
	_etiqueta_enemigos = _crear_etiqueta(panel_amenazas, "AMENAZAS  05", Vector2(20, 48), Vector2(295, 34), fuente, 21, Color(1.0, 0.58, 0.43))

	var panel_controles := _crear_panel(capa, Rect2(24, 626, 595, 68), textura)
	_crear_etiqueta(panel_controles, "WASD / FLECHAS  MOVER     SHIFT  ESQUIVAR     ESPACIO  DISPARAR", Vector2(18, 18), Vector2(555, 30), fuente, 12, Color(0.79, 0.87, 0.90))

	var panel_integridad := _crear_panel(capa, Rect2(920, 613, 335, 81), textura)
	_crear_etiqueta(panel_integridad, "INTEGRIDAD DEL TRAJE", Vector2(18, 9), Vector2(295, 23), fuente, 12, Color(0.79, 0.87, 0.90))
	_barra_integridad = ProgressBar.new()
	_barra_integridad.position = Vector2(18, 39)
	_barra_integridad.size = Vector2(292, 20)
	_barra_integridad.max_value = 100.0
	_barra_integridad.value = 100.0
	_barra_integridad.show_percentage = false
	var fondo_barra := StyleBoxFlat.new()
	fondo_barra.bg_color = Color(0.035, 0.08, 0.13, 0.95)
	fondo_barra.corner_radius_top_left = 4
	fondo_barra.corner_radius_top_right = 4
	fondo_barra.corner_radius_bottom_left = 4
	fondo_barra.corner_radius_bottom_right = 4
	_barra_integridad.add_theme_stylebox_override("background", fondo_barra)
	var relleno_barra := StyleBoxFlat.new()
	relleno_barra.bg_color = Color(0.10, 0.70, 0.93)
	relleno_barra.corner_radius_top_left = 4
	relleno_barra.corner_radius_top_right = 4
	relleno_barra.corner_radius_bottom_left = 4
	relleno_barra.corner_radius_bottom_right = 4
	_barra_integridad.add_theme_stylebox_override("fill", relleno_barra)
	panel_integridad.add_child(_barra_integridad)

	_etiqueta_mensaje = _crear_etiqueta(capa, "", Vector2(350, 150), Vector2(580, 48), fuente, 24, Color(0.55, 0.86, 1.0))
	_etiqueta_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_etiqueta_mensaje.visible = false


func _crear_panel(parent: Node, rectangulo: Rect2, textura: Texture2D) -> NinePatchRect:
	var panel := NinePatchRect.new()
	panel.position = rectangulo.position
	panel.size = rectangulo.size
	panel.texture = textura
	panel.patch_margin_left = 18
	panel.patch_margin_top = 18
	panel.patch_margin_right = 18
	panel.patch_margin_bottom = 18
	parent.add_child(panel)
	return panel


func _crear_etiqueta(parent: Node, texto: String, posicion: Vector2, tamano: Vector2, fuente: Font, tamano_fuente: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.position = posicion
	etiqueta.size = tamano
	etiqueta.add_theme_font_override("font", fuente)
	etiqueta.add_theme_font_size_override("font_size", tamano_fuente)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(etiqueta)
	return etiqueta


func _crear_anillo(radio: float, color: Color, grosor: float, altura: float) -> void:
	_crear_anillo_en(Vector3(0.0, altura, 0.0), radio, color, grosor)


func _crear_anillo_en(posicion: Vector3, radio: float, color: Color, grosor: float) -> void:
	var anillo := MeshInstance3D.new()
	var malla := TorusMesh.new()
	malla.inner_radius = radio - grosor
	malla.outer_radius = radio + grosor
	malla.rings = 12
	malla.ring_segments = 64
	anillo.mesh = malla
	anillo.position = posicion
	anillo.rotation_degrees.x = 90.0
	anillo.material_override = _material(color, 0.2, true)
	add_child(anillo)


func _crear_linea(posicion: Vector3, tamano: Vector3, material: StandardMaterial3D) -> void:
	var linea := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = tamano
	linea.mesh = malla
	linea.position = posicion
	linea.material_override = material
	add_child(linea)


func _crear_bloque(nombre: String, posicion: Vector3, tamano: Vector3, material: StandardMaterial3D, con_colision: bool) -> void:
	var bloque: Node3D
	if con_colision:
		bloque = StaticBody3D.new()
		var colision := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = tamano
		colision.shape = forma
		bloque.add_child(colision)
	else:
		bloque = Node3D.new()
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tamano
	malla.mesh = caja
	malla.material_override = material
	bloque.add_child(malla)
	bloque.name = nombre
	bloque.position = posicion
	add_child(bloque)


func _material(color: Color, metalico: float = 0.0, emitir: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metalico
	material.roughness = 0.48
	if emitir:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.7
	return material
