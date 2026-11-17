extends Control

@onready var play_button: TextureButton = $MenuPanel/MarginContainer/VBoxContainer/PlayButton
@onready var controls_button: TextureButton = $MenuPanel/MarginContainer/VBoxContainer/ControlsButton
@onready var credits_button: TextureButton = $MenuPanel/MarginContainer/VBoxContainer/CreditsButton
@onready var quit_button: TextureButton = $MenuPanel/MarginContainer/VBoxContainer/QuitButton
@onready var info_dimmer: ColorRect = $InfoDimmer
@onready var info_panel: NinePatchRect = $InfoPanel
@onready var info_title: Label = $InfoPanel/MarginContainer/VBoxContainer/Title
@onready var info_text: Label = $InfoPanel/MarginContainer/VBoxContainer/Description
@onready var close_button: TextureButton = $InfoPanel/MarginContainer/VBoxContainer/CloseButton

var _info_visible := false

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	controls_button.pressed.connect(_on_controls_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	close_button.pressed.connect(_on_close_info_pressed)

	for button in [play_button, controls_button, credits_button, quit_button, close_button]:
		button.mouse_entered.connect(_animar_boton.bind(button, 1.04))
		button.mouse_exited.connect(_animar_boton.bind(button, 1.0))

	_animar_fondo()

func _on_play_pressed() -> void:
	var error := get_tree().change_scene_to_file("res://main.tscn")
	if error != OK:
		push_error("No se pudo abrir la escena principal: %s" % error_string(error))


func _on_controls_pressed() -> void:
	_mostrar_info(
		"CONTROLES",
		"MOVERSE: WASD o flechas\nCORRER: Ctrl\nDISPARAR: Espacio (al objetivo más cercano)\nDASH: Shift\nVOLVER AL MENÚ: Esc"
	)


func _on_credits_pressed() -> void:
	_mostrar_info("CRÉDITOS", "EL INQUIETO: ASALTO\n\nUn arcade de supervivencia en una arena isométrica 2D.")


func _mostrar_info(titulo: String, descripcion: String) -> void:
	info_title.text = titulo
	info_text.text = descripcion
	info_dimmer.show()
	info_panel.show()
	_info_visible = true
	close_button.grab_focus()


func _on_close_info_pressed() -> void:
	info_dimmer.hide()
	info_panel.hide()
	_info_visible = false
	controls_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _info_visible and event.is_action_pressed("ui_cancel"):
		_on_close_info_pressed()
		get_viewport().set_input_as_handled()


func _animar_boton(button: Control, escala: float) -> void:
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * escala, 0.12)


func _animar_fondo() -> void:
	var portada := $PortadaFondo as TextureRect
	var movimiento := create_tween().set_loops()
	movimiento.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	movimiento.tween_property(portada, "scale", Vector2(1.035, 1.035), 8.0).from(Vector2(1.015, 1.015))
	movimiento.tween_property(portada, "scale", Vector2(1.015, 1.015), 8.0)
	_crear_ambiente_portada()


func _crear_ambiente_portada() -> void:
	var gradiente := Gradient.new()
	gradiente.set_color(0, Color.WHITE)
	gradiente.set_color(1, Color(1, 1, 1, 0))
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.width = 96
	textura.height = 96

	for posicion in [Vector2(568, 211), Vector2(681, 211)]:
		var luz := PointLight2D.new()
		luz.texture = textura
		luz.texture_scale = 0.65
		luz.color = Color(0.48, 1.0, 0.12)
		luz.energy = 0.75
		luz.position = posicion
		add_child(luz)
		move_child(luz, $MenuPanel.get_index())
		var pulso := create_tween().set_loops()
		pulso.tween_property(luz, "energy", 1.05, 1.4)
		pulso.tween_property(luz, "energy", 0.65, 1.4)

	_crear_particulas(textura, Color(0.45, 1.0, 0.18, 0.7), Vector2(870, 390), 24)
	_crear_particulas(textura, Color(1.0, 0.38, 0.12, 0.65), Vector2(1080, 470), 18)


func _crear_particulas(textura: Texture2D, color: Color, posicion: Vector2, cantidad: int) -> void:
	var particulas := GPUParticles2D.new()
	particulas.position = posicion
	particulas.amount = cantidad
	particulas.lifetime = 7.0
	particulas.preprocess = 3.0
	particulas.visibility_rect = Rect2(-420, -350, 840, 700)
	particulas.texture = textura
	var movimiento := ParticleProcessMaterial.new()
	movimiento.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	movimiento.emission_box_extents = Vector3(260, 300, 0)
	movimiento.direction = Vector3(-0.1, -1, 0)
	movimiento.spread = 18.0
	movimiento.gravity = Vector3(0, -3, 0)
	movimiento.initial_velocity_min = 5.0
	movimiento.initial_velocity_max = 14.0
	movimiento.scale_min = 0.05
	movimiento.scale_max = 0.13
	movimiento.color = color
	particulas.process_material = movimiento
	add_child(particulas)
	move_child(particulas, $MenuPanel.get_index())

func _on_quit_pressed() -> void:
	get_tree().quit()
