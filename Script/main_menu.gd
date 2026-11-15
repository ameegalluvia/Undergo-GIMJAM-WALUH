extends Control

@onready var start: Button = $"MarginContainer/Main Menu/HBoxContainer/Start"
@onready var settings: Button = $"MarginContainer/Main Menu/HBoxContainer/Settings"
@onready var quit: Button = $"MarginContainer/Main Menu/HBoxContainer/Quit"

const MENU_BGM = preload("res://assets/audio/music/Pineapple Under The Sea.ogg")

func _ready() -> void:
	AudioManager.play_music(MENU_BGM, 1.0)

func _on_start_pressed() -> void:
	CutsceneManager.mainkan(preload("res://Data/Cutscene/prolog.tres"))


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/sistem/settings.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
