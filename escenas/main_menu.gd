extends Control

@onready var play_button: TextureButton = $MenuPanel/MarginContainer/VBoxContainer/PlayButton
@onready var controls_button: TextureButton = $MenuPanel/MarginContainer/VBoxContainer/ControlsButton
@onready var credits_button: TextureButton = $MenuPanel/MarginContainer/VBoxContainer/CreditsButton
@onready var quit_button: TextureButton = $MenuPanel/MarginContainer/VBoxContainer/QuitButton
@onready var info_dimmer: ColorRect = $InfoDimmer
@onready var info_panel: Panel = $InfoPanel
@onready var info_title: Label = $InfoPanel/MarginContainer/VBoxContainer/Title
@onready var info_text: Label = $InfoPanel/MarginContainer/VBoxContainer/Description
@onready var close_button: TextureButton = $InfoPanel/MarginContainer/VBoxContainer/CloseButton

var _info_visible := false
var _boton_origen: TextureButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	controls_button.pressed.connect(_on_controls_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	close_button.pressed.connect(_on_close_info_pressed)

	for button in [play_button, controls_button, credits_button, quit_button, close_button]:
		button.mouse_entered.connect(_animar_boton.bind(button, 1.04))
		button.mouse_exited.connect(_animar_boton.bind(button, 1.0))
		button.focus_entered.connect(_animar_boton.bind(button, 1.04))
		button.focus_exited.connect(_animar_boton.bind(button, 1.0))

	var estilo_info := StyleBoxFlat.new()
	estilo_info.bg_color = Color(0.055, 0.026, 0.034, 0.97)
	estilo_info.border_color = Color(0.56, 0.34, 0.20, 1.0)
	estilo_info.set_border_width_all(1)
	estilo_info.set_border_width(SIDE_BOTTOM, 3)
	estilo_info.set_corner_radius_all(3)
	estilo_info.shadow_color = Color(0.01, 0.005, 0.01, 0.75)
	estilo_info.shadow_size = 18
	info_panel.add_theme_stylebox_override("panel", estilo_info)
	info_text.add_theme_color_override("font_color", Color(0.91, 0.86, 0.77))
	info_text.add_theme_font_size_override("font_size", 18)
	info_title.add_theme_color_override("font_color", Color(0.93, 0.83, 0.65))
	call_deferred("_enfocar_jugar")
	_animar_fondo()

func _on_play_pressed() -> void:
	var error := get_tree().change_scene_to_file("res://main.tscn")
	if error != OK:
		push_error("No se pudo abrir la escena principal: %s" % error_string(error))


func _on_controls_pressed() -> void:
	_mostrar_info(
		"CONTROLES",
		"MOVERSE  ·  WASD / FLECHAS\nCORRER  ·  CTRL\nDISPARAR  ·  ESPACIO\nESQUIVAR  ·  SHIFT\nPAUSA  ·  ESC",
		controls_button
	)


func _on_credits_pressed() -> void:
	_mostrar_info(
		"CRÉDITOS",
		"EL INQUIETO: ASALTO\n\nUn arcade de supervivencia en una arena isométrica 2D.",
		credits_button
	)


func _mostrar_info(titulo: String, descripcion: String, boton_origen: TextureButton) -> void:
	_boton_origen = boton_origen
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
	if is_instance_valid(_boton_origen):
		_boton_origen.grab_focus()
	else:
		play_button.grab_focus()
	_boton_origen = null


func _enfocar_jugar() -> void:
	if is_instance_valid(play_button) and not _info_visible:
		play_button.grab_focus()


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
