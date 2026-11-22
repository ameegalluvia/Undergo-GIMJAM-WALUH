extends Node

const SCENE_CUTSCENE := "res://Scene/sistem/cutscene.tscn"

var data_aktif: CutsceneData


func mainkan(data: CutsceneData) -> void:
	data_aktif = data
	get_tree().change_scene_to_file(SCENE_CUTSCENE)
