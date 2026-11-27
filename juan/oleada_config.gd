extends Resource
class_name OleadaConfig

## Parámetros de diseño que consume el spawner de enemigos.

@export_group("Identidad")
@export var nombre: String = "Oleada"
@export var es_jefe: bool = false

@export_group("Aparición")
@export var escena_enemigo: PackedScene
@export var escena_enemigo_alternativo: PackedScene
@export_range(0.0, 1.0, 0.05) var probabilidad_alternativo: float = 0.0
@export var escena_enemigo_terciario: PackedScene
@export_range(0.0, 1.0, 0.05) var probabilidad_terciario: float = 0.0
@export_range(1, 100, 1) var cantidad_enemigos: int = 6
@export_range(0.1, 10.0, 0.05) var intervalo_aparicion: float = 0.9

@export_group("Dificultad")
@export_range(0.1, 10.0, 0.05) var rapidez_formacion: float = 1.2
@export_range(0.2, 20.0, 0.05) var intervalo_disparo: float = 3.0
@export_range(100.0, 1200.0, 10.0) var velocidad_proyectil_rango: float = 420.0
@export_range(1.0, 40.0, 1.0) var dano_proyectil_rango: float = 8.0
@export_range(0, 10000, 10) var puntos_por_enemigo: int = 100
@export_range(1, 100, 1) var integridad_jefe: int = 18

@export_group("Refuerzos del jefe")
@export var escena_refuerzo_cercano: PackedScene
@export var escena_refuerzo_distancia: PackedScene
@export_range(2.0, 30.0, 0.5) var intervalo_refuerzos_jefe: float = 10.0
@export_range(1.0, 10.0, 0.05) var rapidez_refuerzos_jefe: float = 1.25
@export_range(0.2, 20.0, 0.1) var intervalo_disparo_refuerzos_jefe: float = 3.2
@export_range(100.0, 1200.0, 10.0) var velocidad_proyectil_refuerzos_jefe: float = 420.0
@export_range(1.0, 40.0, 1.0) var dano_proyectil_refuerzos_jefe: float = 8.0
@export_range(2, 8, 1) var max_refuerzos_jefe: int = 4

@export_group("Ritmo")
@export_range(0.0, 30.0, 0.5) var pausa_antes_de_la_siguiente: float = 5.0
