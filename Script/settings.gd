extends Control

signal closed
var as_overlay := false   # true kalau dibuka dari pause menu

@onready var master_slider: HSlider = $"MarginContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/VBoxContainer/Master Volume"
@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/VBoxContainer/Musik
@onready var sfx_slider: HSlider = $MarginContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/VBoxContainer/SFX

func _ready() -> void:
	# Pasang nilai awal slider berdasarkan volume saat ini
	master_slider.value = AudioManager.get_volume_linear("Master")
	music_slider.value = AudioManager.get_volume_linear("Music")
	sfx_slider.value = AudioManager.get_volume_linear("SFX")

func _on_master_volume_value_changed(value: float) -> void:
	AudioManager.set_volume_linear("Master", value)

func _on_musik_value_changed(value: float) -> void:
	AudioManager.set_volume_linear("Music", value)

func _on_sfx_value_changed(value: float) -> void:
	AudioManager.set_volume_linear("SFX", value)

func _on_kembali_pressed() -> void:
	if as_overlay:
		closed.emit()
		queue_free()
		return

	# Mode scene biasa (dibuka dari Main Menu)
	if AudioManager.previous_scene_path != "":
		get_tree().change_scene_to_file(AudioManager.previous_scene_path)
	else:
		get_tree().change_scene_to_file("res://Scene/sistem/main_menu.tscn")

func close() -> void:
	_on_kembali_pressed()
