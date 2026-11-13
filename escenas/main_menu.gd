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
	if error == OK:
		get_tree().scene_changed.connect(_iniciar_campana, CONNECT_ONE_SHOT)
	else:
		push_error("No se pudo abrir la escena principal: %s" % error_string(error))


func _iniciar_campana(escena: Node) -> void:
	var director := escena.get_node_or_null("DirectorCampana") as DirectorCampana
	if director != null:
		director.comenzar_campana()


func _on_controls_pressed() -> void:
	_mostrar_info(
		"CONTROLES",
		"MOVERSE: WASD o flechas\nDISPARAR: Espacio\nCORRER: Ctrl\nDASH: Shift\nPAUSA: Esc"
	)


func _on_credits_pressed() -> void:
	_mostrar_info("CREDITOS", "EL INQUIETO: ASALTO\n\nUn arcade de supervivencia en una arena 3D.")


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
	var astronauta := $SubViewportContainer/SubViewport/EscenarioFondo/Astronaut as Node3D
	var jefe_izquierdo := $SubViewportContainer/SubViewport/EscenarioFondo/JefeIzquierdo as Node3D
	var jefe_derecho := $SubViewportContainer/SubViewport/EscenarioFondo/JefeDerecho as Node3D
	var nave_derecha := $SubViewportContainer/SubViewport/EscenarioFondo/NaveDerecha as Node3D
	var animacion := astronauta.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animacion:
		animacion.play("CharacterArmature|Idle_Gun")
	var movimiento := create_tween().set_loops()
	movimiento.tween_property(astronauta, "rotation:y", PI + deg_to_rad(5), 2.5)
	movimiento.tween_property(astronauta, "rotation:y", PI - deg_to_rad(5), 2.5)
	var movimiento_jefes := create_tween().set_loops()
	movimiento_jefes.tween_property(jefe_izquierdo, "position:y", 2.75, 2.0)
	movimiento_jefes.parallel().tween_property(jefe_derecho, "position:y", 2.7, 2.0)
	movimiento_jefes.tween_property(jefe_izquierdo, "position:y", 2.55, 2.0)
	movimiento_jefes.parallel().tween_property(jefe_derecho, "position:y", 2.5, 2.0)
	var movimiento_nave := create_tween().set_loops()
	movimiento_nave.tween_property(nave_derecha, "position:y", 2.85, 2.2)
	movimiento_nave.tween_property(nave_derecha, "position:y", 2.65, 2.2)

func _on_quit_pressed() -> void:
	get_tree().quit()
