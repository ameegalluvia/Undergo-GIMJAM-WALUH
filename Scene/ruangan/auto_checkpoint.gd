extends Node

func _ready() -> void:
	SaveManager.simpan_scene(get_tree().current_scene.scene_file_path)
