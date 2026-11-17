extends Resource
class_name MejoraConfig


enum Tipo {
	DANO_PROYECTIL,
	CADENCIA_DISPARO,
	VELOCIDAD
}


@export_group("Identidad")
@export var id: StringName = &""
@export var nombre: String = "Mejora"
@export_multiline var descripcion: String = ""


@export_group("Efecto")
@export var tipo: Tipo = Tipo.DANO_PROYECTIL
@export_range(0.0, 1.0, 0.01) var valor: float = 0.0
