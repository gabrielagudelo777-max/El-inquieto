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
		"MOVERSE: WASD o flechas\nDISPARAR: Espacio (al objetivo más cercano)\nDASH: Shift\nVOLVER AL MENÚ: Esc"
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
	var enemigo := $SubViewportContainer/SubViewport/EscenarioFondo/Enemigo as Node3D
	var animacion := astronauta.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animacion:
		animacion.play("CharacterArmature|Idle_Gun")
	var movimiento := create_tween().set_loops()
	movimiento.tween_property(astronauta, "rotation:y", deg_to_rad(-5), 2.5)
	movimiento.tween_property(astronauta, "rotation:y", deg_to_rad(5), 2.5)
	var enemigo_movimiento := create_tween().set_loops()
	enemigo_movimiento.tween_property(enemigo, "rotation:y", deg_to_rad(-8), 3.0)
	enemigo_movimiento.tween_property(enemigo, "rotation:y", deg_to_rad(8), 3.0)

func _on_quit_pressed() -> void:
	get_tree().quit()
