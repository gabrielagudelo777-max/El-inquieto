extends Control

@onready var play_button: TextureButton = $MenuPanel/MarginContainer/VBoxContainer/PlayButton
@onready var options_button: TextureButton = $MenuPanel/MarginContainer/VBoxContainer/OptionsButton
@onready var quit_button: TextureButton = $MenuPanel/MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	# Reemplaza esta ruta por la escena de tu nivel principal cuando esté lista
	print("Iniciando El Inquieto...")
	# get_tree().change_scene_to_file("res://escenas/nivel_1.tscn")

func _on_options_pressed() -> void:
	print("Abriendo opciones...")

func _on_quit_pressed() -> void:
	get_tree().quit()
