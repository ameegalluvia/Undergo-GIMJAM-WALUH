extends Control

@onready var start: Button = $"MarginContainer/Main Menu/HBoxContainer/Start"
@onready var settings: Button = $"MarginContainer/Main Menu/HBoxContainer/Settings"
@onready var quit: Button = $"MarginContainer/Main Menu/HBoxContainer/Quit"

const MENU_BGM = preload("res://assets/audio/music/ubed ganteng.mp3")

func _ready() -> void:
	$"MarginContainer/Main Menu/HBoxContainer/Continue".disabled = not SaveManager.ada_save()
	AudioManager.play_music(MENU_BGM, 1.0)

func _on_start_pressed() -> void:
<<<<<<< Updated upstream
	get_tree().change_scene_to_file("res://Scene/ruangan/bioskop.tscn")

=======
	CutsceneManager.mainkan(preload("res://Data/Cutscene/prolog.tres"))
	SaveManager.game_baru()
>>>>>>> Stashed changes

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/sistem/settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_continue_pressed() -> void:
	SaveManager.lanjutkan()
