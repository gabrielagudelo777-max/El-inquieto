extends Node3D
## Elementos artísticos de la plaza, construidos con mallas básicas de Godot.
## Mantener los pasillos centrales despejados para la jugabilidad.

var mats: Dictionary = {}


func _ready() -> void:
	_crear_materiales()
	_crear_medallon_central()
	_crear_fachadas()
	_crear_palmeras()
	_crear_faroles()
	_crear_materas()
	_crear_banderines()


func _crear_materiales() -> void:
	mats = {
		"piedra": _material(Color("#192a3b")),
		"piedra_clara": _material(Color("#34485a")),
		"turquesa": _material(Color("#20d6c7"), 0.55),
		"coral": _material(Color("#ff5868"), 0.35),
		"amarillo": _material(Color("#ffc857"), 0.3),
		"verde": _material(Color("#3f9b73")),
		"hoja": _material(Color("#63c991")),
		"tierra": _material(Color("#403241")),
		"vidrio": _material(Color("#75d9e5"), 0.7),
		"morado": _material(Color("#704bc2")),
		"madera": _material(Color("#704b3d")),
		"negro": _material(Color("#101622")),
	}


func _material(color: Color, brillo: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.68
	if brillo > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = brillo
	return material


func _caja(parent: Node, nombre: String, tamano: Vector3, posicion: Vector3, material: Material) -> MeshInstance3D:
	var malla := BoxMesh.new()
	malla.size = tamano
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = malla
	nodo.position = posicion
	nodo.material_override = material
	parent.add_child(nodo)
	return nodo


func _cilindro(parent: Node, nombre: String, radio: float, alto: float, posicion: Vector3, material: Material, lados: int = 12) -> MeshInstance3D:
	var malla := CylinderMesh.new()
	malla.top_radius = radio
	malla.bottom_radius = radio
	malla.height = alto
	malla.radial_segments = lados
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = malla
	nodo.position = posicion
	nodo.material_override = material
	parent.add_child(nodo)
	return nodo


func _esfera(parent: Node, nombre: String, radio: float, posicion: Vector3, material: Material) -> MeshInstance3D:
	var malla := SphereMesh.new()
	malla.radius = radio
	malla.height = radio * 2.0
	malla.radial_segments = 10
	malla.rings = 6
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = malla
	nodo.position = posicion
	nodo.material_override = material
	parent.add_child(nodo)
	return nodo


func _letrero(parent: Node, texto: String, posicion: Vector3, color: Color, tamano: int = 30) -> Label3D:
	var label := Label3D.new()
	label.text = texto
	label.position = posicion
	label.pixel_size = 0.012
	label.font_size = tamano
	label.outline_size = 7
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	parent.add_child(label)
	return label


func _crear_medallon_central() -> void:
	var centro := Node3D.new()
	centro.name = "MedallonCentral"
	add_child(centro)
	_cilindro(centro, "BordeExterior", 2.8, 0.06, Vector3(0, 0.025, -0.5), mats.piedra_clara, 48)
	_cilindro(centro, "AnilloTurquesa", 2.48, 0.075, Vector3(0, 0.065, -0.5), mats.turquesa, 48)
	_cilindro(centro, "CentroOscuro", 2.12, 0.08, Vector3(0, 0.11, -0.5), mats.piedra, 48)
	_cilindro(centro, "IslaCentral", 1.65, 0.10, Vector3(0, 0.17, -0.5), mats.morado, 48)
	_cilindro(centro, "Emblema", 0.68, 0.13, Vector3(0, 0.26, -0.5), mats.amarillo, 32)
	_letrero(centro, "REENVÍO", Vector3(0, 0.42, -0.5), Color("#fff2ca"), 24)
	# Pequeños marcadores radiales que rompen la gran superficie vacía del asfalto.
	for indice in 12:
		var angulo := TAU * float(indice) / 12.0
		var marca := _caja(centro, "MarcaRadial%02d" % indice, Vector3(0.10, 0.035, 0.52), Vector3(sin(angulo) * 3.28, 0.035, -0.5 + cos(angulo) * 3.28), mats.amarillo if indice % 2 == 0 else mats.coral)
		marca.rotation.y = -angulo


func _crear_fachadas() -> void:
	var fachadas := [
		{"nombre": "La Esquina Viral", "x": -8.7, "color": mats.coral, "texto": "LA ESQUINA", "detalle": "CHISME  •  TINTO"},
		{"nombre": "Pixel Paisa", "x": 0.0, "color": mats.turquesa, "texto": "PIXEL PAISA", "detalle": "MEMES  •  EN VIVO"},
		{"nombre": "El Reenvio", "x": 8.7, "color": mats.amarillo, "texto": "EL REENVÍO", "detalle": "TODO SE SABE"},
	]
	for datos in fachadas:
		var local := Node3D.new()
		local.name = datos.nombre
		local.position = Vector3(datos.x, 0.0, -9.55)
		add_child(local)
		_caja(local, "Fachada", Vector3(7.2, 3.65, 1.05), Vector3(0, 1.825, 0), mats.piedra)
		_caja(local, "FranjaColor", Vector3(7.28, 0.22, 1.12), Vector3(0, 3.44, 0), datos.color)
		_caja(local, "Vitrina", Vector3(5.3, 1.3, 0.08), Vector3(0, 1.83, 0.57), mats.vidrio)
		_caja(local, "MarcoVitrina", Vector3(5.55, 0.12, 0.14), Vector3(0, 2.53, 0.61), mats.amarillo)
		_caja(local, "Mostrador", Vector3(4.9, 0.18, 0.38), Vector3(0, 1.1, 0.72), mats.madera)
		_caja(local, "Puerta", Vector3(1.05, 2.35, 0.10), Vector3(2.75, 1.18, 0.59), mats.negro)
		_caja(local, "Toldo", Vector3(7.55, 0.28, 1.0), Vector3(0, 2.86, 0.94), datos.color)
		for indice in 7:
			_caja(local, "GajoToldo%02d" % indice, Vector3(0.12, 0.29, 1.03), Vector3(-3.2 + indice * 1.07, 2.86, 0.96), mats.amarillo if indice % 2 == 0 else mats.piedra)
		_letrero(local, datos.texto, Vector3(0, 3.12, 1.02), Color("#fff4d7"), 32)
		_letrero(local, datos.detalle, Vector3(0, 0.78, 0.69), Color("#f8d9b4"), 17)


func _crear_palmeras() -> void:
	for indice in 4:
		var x := -13.0 if indice % 2 == 0 else 13.0
		var z := -7.0 if indice < 2 else 7.0
		var palmera := Node3D.new()
		palmera.name = "Palmera%02d" % indice
		palmera.position = Vector3(x, 0, z)
		add_child(palmera)
		_cilindro(palmera, "Maceta", 0.95, 0.38, Vector3(0, 0.19, 0), mats.coral, 8)
		_cilindro(palmera, "Tierra", 0.78, 0.12, Vector3(0, 0.43, 0), mats.tierra, 8)
		_cilindro(palmera, "Tronco", 0.24, 2.65, Vector3(0, 1.72, 0), mats.madera, 8)
		_esfera(palmera, "Copa", 0.62, Vector3(0, 3.08, 0), mats.verde)
		for hoja in 6:
			var angulo := TAU * float(hoja) / 6.0
			var rama := _caja(palmera, "Hoja%02d" % hoja, Vector3(0.34, 0.11, 2.0), Vector3(sin(angulo) * 0.78, 3.08, cos(angulo) * 0.78), mats.hoja)
			rama.rotation.y = angulo
			rama.rotation.x = -0.28
		_esfera(palmera, "Coco", 0.19, Vector3(0.18, 2.88, 0.16), mats.amarillo)


func _crear_faroles() -> void:
	for indice in 6:
		var x := -10.0 + float(indice) * 4.0
		var z := 8.4 if indice % 2 == 0 else -5.2
		var farol := Node3D.new()
		farol.name = "Farol%02d" % indice
		farol.position = Vector3(x, 0.0, z)
		add_child(farol)
		_cilindro(farol, "Base", 0.34, 0.26, Vector3(0, 0.13, 0), mats.piedra_clara, 10)
		_cilindro(farol, "Poste", 0.10, 3.0, Vector3(0, 1.63, 0), mats.negro, 8)
		_caja(farol, "Brazo", Vector3(0.75, 0.10, 0.10), Vector3(0.27, 3.02, 0), mats.negro)
		_esfera(farol, "Luz", 0.32, Vector3(0.55, 2.9, 0), mats.amarillo)
		var luz := OmniLight3D.new()
		luz.name = "Resplandor"
		luz.position = Vector3(0.55, 2.72, 0)
		luz.light_color = Color("#ffca77")
		luz.light_energy = 0.55
		luz.omni_range = 4.2
		farol.add_child(luz)


func _crear_materas() -> void:
	var ubicaciones := [Vector3(-11, 0, 0), Vector3(11, 0, 0), Vector3(-5.5, 0, -3.0), Vector3(5.5, 0, -3.0)]
	for indice in ubicaciones.size():
		var matera := Node3D.new()
		matera.name = "Matera%02d" % indice
		matera.position = ubicaciones[indice]
		add_child(matera)
		_cilindro(matera, "Contenedor", 0.75, 0.58, Vector3(0, 0.29, 0), mats.morado, 8)
		_cilindro(matera, "Tierra", 0.63, 0.10, Vector3(0, 0.63, 0), mats.tierra, 8)
		for hoja in 5:
			var angulo := TAU * float(hoja) / 5.0
			_esfera(matera, "Arbusto%02d" % hoja, 0.43, Vector3(sin(angulo) * 0.32, 1.0, cos(angulo) * 0.32), mats.hoja if hoja % 2 == 0 else mats.verde)


func _crear_banderines() -> void:
	for indice in 9:
		var x := -9.0 + float(indice) * 2.25
		var banderin := _caja(self, "Banderin%02d" % indice, Vector3(0.58, 0.10, 0.85), Vector3(x, 5.7, -4.8 + absf(x) * 0.06), mats.amarillo if indice % 3 == 0 else (mats.coral if indice % 3 == 1 else mats.turquesa))
		banderin.rotation.z = -0.14 if indice % 2 == 0 else 0.14
		_caja(self, "CableBanderines%02d" % indice, Vector3(0.035, 0.035, 0.035), Vector3(x, 6.08, -4.75), mats.negro)
