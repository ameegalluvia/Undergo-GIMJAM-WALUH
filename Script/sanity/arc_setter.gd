extends Node

@export var sanity_aktif := false

func _ready() -> void:
	if sanity_aktif:
		SanityManager.aktifkan()
	else:
		SanityManager.nonaktifkan()
