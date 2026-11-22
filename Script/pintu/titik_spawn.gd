extends Marker2D

@export var id_titik: StringName

func _ready() -> void:
	add_to_group("titik_spawn")
