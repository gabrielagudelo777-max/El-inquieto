extends Node3D

const ASTRONAUTA = "res://assets/quaternius_ultimate_space/Astronaut.glb"
const ALIEN = "res://assets/quaternius_modular_scifi/glTF/Aliens/Alien_Scolitex.gltf"
const NEBULOSA = "res://assets/kenney_skyboxes_space/Skyboxes/skybox-space-nebula.png"
const EMBLEMA_NAVE = "res://assets/naves_larzes/Ship_1_A_Medium.png"
const EMBLEMA_JEFE = "res://assets/naves_larzes/Boss_1_A_Medium.png"
const EMBLEMA_ALIEN = "res://assets/naves_larzes/Enemy_1_A_Medium.png"
const EMBLEMA_ALIEN_SECUNDARIO = "res://assets/naves_larzes/Enemy_4_B_Medium.png"
const PANEL_HUD = "res://assets/1. Free Hologram Interface Wenrexa/1. Free Hologram Interface Wenrexa/Card X1/Panel Empty Green.png"
const TIPOGRAFIA = "res://assets/fonts/CinzelDecorative-Regular.ttf"
const SCRIPT_JUGADOR = preload("res://juan/jugador_batalla.gd")
const SCRIPT_ALIEN = preload("res://juan/enemigo_batalla.gd")
const SCRIPT_DIRECTOR = preload("res://juan/director_campana.gd")
const ESCENA_UI_CAMPANA = preload("res://juan/ui_campana.tscn")
const RUTAS_OLEADAS := [
	"res://juan/oleadas/oleada_01.tres",
	"res://juan/oleadas/oleada_02.tres",
	"res://juan/oleadas/oleada_03.tres",
	"res://juan/oleadas/oleada_04.tres",
	"res://juan/oleadas/oleada_05.tres",
	"res://juan/oleadas/oleada_06_jefe.tres",
]

var _jugador: CharacterBody3D
var _etiqueta_enemigos: Label
var _barra_integridad: ProgressBar
var _etiqueta_mensaje: Label
var _director: DirectorCampana
var _configuracion_oleada: OleadaConfig
var _enemigos_por_aparecer := 0
var _temporizador_aparicion := 0.0
var _escena_aliens: PackedScene


func _ready() -> void:
	add_to_group("control_arena")
	_crear_entorno()
	_crear_arena()
	_crear_jugador()
	_crear_campana()
	_crear_camara()
	_crear_interfaz()


func _process(_delta: float) -> void:
	if _enemigos_por_aparecer > 0 and _director != null and _director.estado == DirectorCampana.Estado.COMBATE:
		_temporizador_aparicion -= _delta
		if _temporizador_aparicion <= 0.0:
			_aparecer_enemigo()
			_enemigos_por_aparecer -= 1
			_temporizador_aparicion = _configuracion_oleada.intervalo_aparicion
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
	suelo.name = "SueloDePiedra"
	var malla_suelo := MeshInstance3D.new()
	var caja_suelo := BoxMesh.new()
	caja_suelo.size = Vector3(20.0, 0.65, 20.0)
	malla_suelo.mesh = caja_suelo
	malla_suelo.position.y = -0.36
	malla_suelo.material_override = _material(Color(0.065, 0.052, 0.085), 0.22)
	suelo.add_child(malla_suelo)
	var colision_suelo := CollisionShape3D.new()
	var forma_suelo := BoxShape3D.new()
	forma_suelo.size = caja_suelo.size
	colision_suelo.shape = forma_suelo
	colision_suelo.position.y = -0.36
	suelo.add_child(colision_suelo)
	add_child(suelo)

	_crear_losas()
	var material_piedra := _material(Color(0.12, 0.085, 0.12), 0.32)
	var material_muro := _material(Color(0.105, 0.075, 0.105), 0.34)
	var material_bronce := _material(Color(0.55, 0.34, 0.14), 0.68)
	var material_cian := _material(Color(0.035, 0.42, 0.66), 0.24, true)
	var material_linea := _material(Color(0.035, 0.48, 0.75), 0.25, true)
	var material_cubierta := _material(Color(0.12, 0.14, 0.23), 0.58)

	# Cuatro paredes cerradas contienen al jugador y las oleadas.
	_crear_bloque("Muro_Norte", Vector3(0.0, 1.62, -9.55), Vector3(20.0, 3.3, 0.75), material_muro, true)
	_crear_bloque("Muro_Sur", Vector3(0.0, 1.62, 9.55), Vector3(20.0, 3.3, 0.75), material_muro, true)
	_crear_bloque("Muro_Este", Vector3(9.55, 1.62, 0.0), Vector3(0.75, 3.3, 20.0), material_muro, true)
	_crear_bloque("Muro_Oeste", Vector3(-9.55, 1.62, 0.0), Vector3(0.75, 3.3, 20.0), material_muro, true)
	_crear_moldura_muros(material_bronce, material_cian)
	_crear_portal_oleadas(material_piedra, material_bronce, material_cian)

	for posicion in [Vector3(-8.15, 0.0, -8.15), Vector3(8.15, 0.0, -8.15), Vector3(-8.15, 0.0, 8.15), Vector3(8.15, 0.0, 8.15)]:
		_crear_columna(posicion, material_piedra, material_bronce, material_cian)
	for posicion in [Vector3(-6.9, 0.0, -6.9), Vector3(6.9, 0.0, -6.9), Vector3(-6.9, 0.0, 6.9), Vector3(6.9, 0.0, 6.9)]:
		_crear_brasero(posicion, material_bronce)

	_crear_mural(EMBLEMA_NAVE, Vector3(-6.0, 2.0, -9.14), 0.0)
	_crear_mural(EMBLEMA_JEFE, Vector3(6.0, 2.0, -9.14), 0.0)
	_crear_mural(EMBLEMA_ALIEN, Vector3(-9.14, 2.0, 0.0), PI * 0.5)
	_crear_mural(EMBLEMA_ALIEN_SECUNDARIO, Vector3(9.14, 2.0, 0.0), -PI * 0.5)

	var centro := MeshInstance3D.new()
	var malla_centro := CylinderMesh.new()
	malla_centro.top_radius = 2.35
	malla_centro.bottom_radius = 2.55
	malla_centro.height = 0.10
	centro.mesh = malla_centro
	centro.position.y = 0.02
	centro.material_override = _material(Color(0.11, 0.075, 0.12), 0.52)
	add_child(centro)
	_crear_anillo(2.85, Color(0.08, 0.66, 1.0), 0.055, 0.10)
	_crear_anillo(3.12, Color(0.82, 0.49, 0.19), 0.035, 0.06)
	_crear_anillo(1.32, Color(0.68, 0.38, 0.16), 0.025, 0.09)

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

	var lucesuelo := load("res://assets/quaternius_modular_scifi/glTF/Props/Prop_Light_Floor.gltf") as PackedScene
	if lucesuelo:
		for posicion in [Vector3(-7.8, 0.0, -7.8), Vector3(7.8, 0.0, -7.8), Vector3(-7.8, 0.0, 7.8), Vector3(7.8, 0.0, 7.8)]:
			var pieza := lucesuelo.instantiate()
			pieza.position = posicion
			pieza.scale = Vector3.ONE * 0.56
			add_child(pieza)


func _crear_losas() -> void:
	var piedra_a := _material(Color(0.13, 0.09, 0.12), 0.12)
	var piedra_b := _material(Color(0.095, 0.085, 0.125), 0.16)
	for fila in 6:
		for columna in 6:
			var losa := MeshInstance3D.new()
			var malla := BoxMesh.new()
			malla.size = Vector3(3.06, 0.08, 3.06)
			losa.mesh = malla
			losa.position = Vector3(-7.8 + columna * 3.12, 0.0, -7.8 + fila * 3.12)
			losa.material_override = piedra_a if (fila + columna) % 2 == 0 else piedra_b
			add_child(losa)

	var bronce := _material(Color(0.46, 0.28, 0.12), 0.62)
	for indice in 5:
		var desplazamiento := -6.24 + indice * 3.12
		_crear_linea(Vector3(desplazamiento, 0.048, -9.0), Vector3(0.045, 0.02, 18.0), bronce)
		_crear_linea(Vector3(-9.0, 0.048, desplazamiento), Vector3(18.0, 0.02, 0.045), bronce)

	var cian := _material(Color(0.04, 0.43, 0.68), 0.22, true)
	for indice in 8:
		var angulo := TAU * float(indice) / 8.0
		var posicion := Vector3(cos(angulo) * 3.42, 0.06, sin(angulo) * 3.42)
		var runa := MeshInstance3D.new()
		var malla_runa := BoxMesh.new()
		malla_runa.size = Vector3(0.42, 0.035, 0.075)
		runa.mesh = malla_runa
		runa.position = posicion
		runa.rotation.y = -angulo
		runa.material_override = cian if indice % 2 == 0 else bronce
		add_child(runa)


func _crear_moldura_muros(material_bronce: StandardMaterial3D, material_cian: StandardMaterial3D) -> void:
	for altura in [0.24, 2.98]:
		_crear_linea(Vector3(0.0, altura, -9.14), Vector3(19.4, 0.11, 0.10), material_bronce)
		_crear_linea(Vector3(0.0, altura, 9.14), Vector3(19.4, 0.11, 0.10), material_bronce)
		_crear_linea(Vector3(-9.14, altura, 0.0), Vector3(0.10, 0.11, 19.4), material_bronce)
		_crear_linea(Vector3(9.14, altura, 0.0), Vector3(0.10, 0.11, 19.4), material_bronce)
	var luz := material_cian
	for indice in 8:
		var x := -8.0 + indice * 2.28
		_crear_linea(Vector3(x, 0.62, -9.135), Vector3(0.72, 0.06, 0.09), luz)
		_crear_linea(Vector3(x, 0.62, 9.135), Vector3(0.72, 0.06, 0.09), luz)
		_crear_linea(Vector3(-9.135, 0.62, x), Vector3(0.09, 0.06, 0.72), luz)
		_crear_linea(Vector3(9.135, 0.62, x), Vector3(0.09, 0.06, 0.72), luz)


func _crear_portal_oleadas(piedra: StandardMaterial3D, bronce: StandardMaterial3D, cian: StandardMaterial3D) -> void:
	for lado in [-1.0, 1.0]:
		_crear_bloque("Jamba_Portal", Vector3(lado * 1.85, 1.55, -9.08), Vector3(0.42, 3.0, 0.42), piedra, false)
		_crear_bloque("Capitel_Portal", Vector3(lado * 1.85, 3.05, -9.08), Vector3(0.82, 0.26, 0.64), bronce, false)
	_crear_bloque("Dintel_Portal", Vector3(0.0, 3.16, -9.08), Vector3(3.55, 0.34, 0.42), piedra, false)
	var placa := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2.45, 2.40)
	placa.mesh = quad
	placa.position = Vector3(0.0, 1.60, -9.115)
	placa.material_override = cian
	add_child(placa)
	var aura := OmniLight3D.new()
	aura.position = Vector3(0.0, 1.6, -8.55)
	aura.light_color = Color(0.06, 0.53, 0.95)
	aura.light_energy = 3.0
	aura.omni_range = 6.0
	add_child(aura)
	_crear_linea(Vector3(0.0, 3.36, -9.0), Vector3(2.75, 0.045, 0.08), bronce)


func _crear_columna(posicion: Vector3, piedra: StandardMaterial3D, bronce: StandardMaterial3D, cian: StandardMaterial3D) -> void:
	var columna := StaticBody3D.new()
	columna.name = "Columna_Dungeon"
	columna.position = posicion
	var colision := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = 0.43
	forma.height = 3.05
	colision.shape = forma
	colision.position.y = 1.52
	columna.add_child(colision)
	_crear_cilindro(columna, "Base", Vector3(0.0, 0.14, 0.0), 0.57, 0.57, 0.28, bronce)
	_crear_cilindro(columna, "Fuste", Vector3(0.0, 1.55, 0.0), 0.33, 0.40, 2.55, piedra)
	_crear_cilindro(columna, "Capitel", Vector3(0.0, 2.92, 0.0), 0.56, 0.37, 0.28, bronce)
	_crear_cilindro(columna, "Aro_Cian", Vector3(0.0, 0.44, 0.0), 0.43, 0.43, 0.075, cian)
	_crear_cilindro(columna, "Aro_Cian", Vector3(0.0, 2.65, 0.0), 0.39, 0.39, 0.07, cian)
	for ranura in 8:
		var angulo := TAU * float(ranura) / 8.0
		var acanaladura := MeshInstance3D.new()
		var malla := BoxMesh.new()
		malla.size = Vector3(0.045, 2.12, 0.055)
		acanaladura.mesh = malla
		acanaladura.position = Vector3(cos(angulo) * 0.315, 1.55, sin(angulo) * 0.315)
		acanaladura.material_override = cian if ranura % 2 == 0 else bronce
		columna.add_child(acanaladura)
	add_child(columna)


func _crear_brasero(posicion: Vector3, bronce: StandardMaterial3D) -> void:
	var brasero := StaticBody3D.new()
	brasero.name = "Brasero"
	brasero.position = posicion
	var colision := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = 0.36
	forma.height = 0.95
	colision.shape = forma
	colision.position.y = 0.48
	brasero.add_child(colision)
	_crear_cilindro(brasero, "Pedestal", Vector3(0.0, 0.28, 0.0), 0.31, 0.40, 0.56, bronce)
	_crear_cilindro(brasero, "Copa", Vector3(0.0, 0.70, 0.0), 0.47, 0.27, 0.24, bronce)
	var llama := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.19
	esfera.height = 0.58
	llama.mesh = esfera
	llama.position.y = 1.02
	llama.material_override = _material(Color(1.0, 0.40, 0.10), 0.0, true)
	brasero.add_child(llama)
	var luz := OmniLight3D.new()
	luz.position.y = 1.10
	luz.light_color = Color(1.0, 0.39, 0.12)
	luz.light_energy = 1.8
	luz.omni_range = 4.0
	brasero.add_child(luz)
	add_child(brasero)


func _crear_mural(ruta_textura: String, posicion: Vector3, rotacion_y: float) -> void:
	var textura := load(ruta_textura) as Texture2D
	if textura == null:
		return
	var mural := Node3D.new()
	mural.name = "Estandarte"
	mural.position = posicion
	mural.rotation.y = rotacion_y
	var fondo := MeshInstance3D.new()
	var malla_fondo := BoxMesh.new()
	malla_fondo.size = Vector3(2.5, 2.65, 0.12)
	fondo.mesh = malla_fondo
	fondo.material_override = _material(Color(0.10, 0.07, 0.12), 0.55)
	mural.add_child(fondo)
	var marco := StandardMaterial3D.new()
	marco.albedo_color = Color(0.58, 0.37, 0.17)
	marco.metallic = 0.72
	marco.roughness = 0.34
	for y in [-1.28, 1.28]:
		var barra := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = Vector3(2.56, 0.075, 0.16)
		barra.mesh = caja
		barra.position.y = y
		barra.material_override = marco
		mural.add_child(barra)
	for x in [-1.24, 1.24]:
		var barra := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = Vector3(0.075, 2.56, 0.16)
		barra.mesh = caja
		barra.position.x = x
		barra.material_override = marco
		mural.add_child(barra)
	var quad := QuadMesh.new()
	quad.size = Vector2(2.15, 2.20)
	var placa := MeshInstance3D.new()
	placa.mesh = quad
	placa.position.z = 0.09
	var material_sprite := StandardMaterial3D.new()
	material_sprite.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_sprite.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_sprite.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_sprite.albedo_texture = textura
	material_sprite.emission_enabled = true
	material_sprite.emission = Color(0.12, 0.28, 0.46)
	material_sprite.emission_energy_multiplier = 0.30
	placa.material_override = material_sprite
	mural.add_child(placa)
	add_child(mural)


func _crear_cilindro(parent: Node3D, nombre: String, posicion: Vector3, radio_superior: float, radio_inferior: float, altura: float, material: StandardMaterial3D) -> void:
	var cilindro := MeshInstance3D.new()
	cilindro.name = nombre
	var malla := CylinderMesh.new()
	malla.top_radius = radio_superior
	malla.bottom_radius = radio_inferior
	malla.height = altura
	cilindro.mesh = malla
	cilindro.position = posicion
	cilindro.material_override = material
	parent.add_child(cilindro)


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


func _crear_campana() -> void:
	_director = SCRIPT_DIRECTOR.new() as DirectorCampana
	_director.name = "DirectorCampana"
	for ruta in RUTAS_OLEADAS:
		var configuracion := load(ruta) as OleadaConfig
		if configuracion != null:
			_director.oleadas.append(configuracion)
	add_child(_director)
	_director.oleada_iniciada.connect(_iniciar_oleada)
	_director.estado_cambiado.connect(_al_cambiar_estado_campana)
	_escena_aliens = load(ALIEN) as PackedScene
	var interfaz := ESCENA_UI_CAMPANA.instantiate()
	add_child(interfaz)
	_director.comenzar_campana()


func _al_cambiar_estado_campana(estado: int) -> void:
	if estado == DirectorCampana.Estado.INTRO or estado == DirectorCampana.Estado.COMBATE or estado == DirectorCampana.Estado.INTRO_JEFE or estado == DirectorCampana.Estado.MENU:
		_enemigos_por_aparecer = 0
		_configuracion_oleada = null
		for enemigo in get_tree().get_nodes_in_group("enemigos"):
			if is_instance_valid(enemigo):
				enemigo.queue_free()
	if estado == DirectorCampana.Estado.INTRO or (estado == DirectorCampana.Estado.COMBATE and _director.indice_oleada < 0):
		if is_instance_valid(_jugador):
			_jugador.set("integridad", 100.0)
			if is_instance_valid(_barra_integridad):
				_barra_integridad.value = 100.0


func _iniciar_oleada(_indice: int, configuracion: OleadaConfig) -> void:
	_configuracion_oleada = configuracion
	_enemigos_por_aparecer = configuracion.cantidad_enemigos
	_temporizador_aparicion = 0.0


func _aparecer_enemigo() -> void:
	var alien := CharacterBody3D.new()
	var numero := _configuracion_oleada.cantidad_enemigos - _enemigos_por_aparecer + 1
	alien.name = "Amenaza_%02d_%02d" % [_director.indice_oleada + 1, numero]
	var carril := (numero - 1) % 5
	var carriles_x := [-7.0, -3.5, 0.0, 3.5, 7.0]
	alien.position = Vector3(carriles_x[carril], 0.0, -7.2 - float((numero - 1) / 5) * 1.2)
	alien.set_script(SCRIPT_ALIEN)
	alien.call("configurar_oleada", _configuracion_oleada.rapidez_formacion, _configuracion_oleada.intervalo_disparo, _configuracion_oleada.puntos_por_enemigo, _configuracion_oleada.es_jefe)
	var colision := CollisionShape3D.new()
	var capsula := CapsuleShape3D.new()
	capsula.radius = 0.48 if not _configuracion_oleada.es_jefe else 0.78
	capsula.height = 1.5 if not _configuracion_oleada.es_jefe else 2.2
	colision.shape = capsula
	colision.position.y = capsula.height * 0.5
	alien.add_child(colision)
	if _escena_aliens:
		var modelo := _escena_aliens.instantiate()
		modelo.name = "ModeloAlien"
		modelo.scale = Vector3.ONE * (0.55 if not _configuracion_oleada.es_jefe else 0.9)
		alien.add_child(modelo)
	add_child(alien)


func _crear_camara() -> void:
	var camara := Camera3D.new()
	camara.name = "CamaraArena"
	camara.position = Vector3(0.0, 17.5, 19.0)
	camara.projection = Camera3D.PROJECTION_ORTHOGONAL
	camara.size = 23.5
	add_child(camara)
	camara.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
	camara.current = true


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
