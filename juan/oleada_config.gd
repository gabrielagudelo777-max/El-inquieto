extends Resource
class_name OleadaConfig

## Parámetros de diseño que consume el spawner de enemigos.

@export_group("Identidad")
@export var nombre: String = "Oleada"
@export var es_jefe: bool = false

@export_group("Aparición")
@export var escena_enemigo: PackedScene
@export_range(1, 100, 1) var cantidad_enemigos: int = 6
@export_range(0.1, 10.0, 0.05) var intervalo_aparicion: float = 0.9

@export_group("Dificultad")
@export_range(0.1, 10.0, 0.05) var rapidez_formacion: float = 1.2
@export_range(0.2, 20.0, 0.05) var intervalo_disparo: float = 3.0
@export_range(0, 10000, 10) var puntos_por_enemigo: int = 100

@export_group("Ritmo")
@export_range(0.0, 30.0, 0.5) var pausa_antes_de_la_siguiente: float = 5.0
