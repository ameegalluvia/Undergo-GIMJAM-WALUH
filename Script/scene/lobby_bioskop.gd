extends Node

const GAMEPLAY_BGM = preload("res://assets/audio/music/gameplay_explore_horror.wav")

func _ready() -> void:
	AudioManager.play_music(GAMEPLAY_BGM)
