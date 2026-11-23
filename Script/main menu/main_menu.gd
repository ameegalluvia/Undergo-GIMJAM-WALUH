extends Control

const MENU_BGM = preload("res://assets/audio/music/ubed ganteng.mp3")

func _ready() -> void:
	AudioManager.play_music(MENU_BGM)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/ruangan/lobby_bioskop.tscn")
	SaveManager.game_baru()

func _on_settings_pressed() -> void:
	# Simpan bahwa kita berasal dari Main Menu
	AudioManager.previous_scene_path = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file("res://Scene/sistem/settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_continue_pressed() -> void:
	SaveManager.lanjutkan()
