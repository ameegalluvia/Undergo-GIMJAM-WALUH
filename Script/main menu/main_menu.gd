extends Control

const MENU_BGM = preload("res://assets/audio/music/ubed ganteng.mp3")
const SCENE_AWAL_PATH := "res://Scene/ruangan/lobby_bioskop.tscn"
const SETTINGS_SCENE_PATH := "res://Scene/sistem/settings.tscn"

func _ready() -> void:
	AudioManager.play_music(MENU_BGM)

func _on_start_pressed() -> void:
	if Transisi.sedang_transisi:
		return
	_kunci_tombol()
	await Transisi.fade_keluar_dan_jalankan(func() -> void:
		SaveManager.game_baru()
		get_tree().change_scene_to_file(SCENE_AWAL_PATH)
	, true)

func _on_continue_pressed() -> void:
	if Transisi.sedang_transisi:
		return
	if not SaveManager.ada_save():
		return
	_kunci_tombol()
	await Transisi.fade_keluar_dan_jalankan(func() -> void:
		SaveManager.lanjutkan()
	, true)

func _on_settings_pressed() -> void:
	if Transisi.sedang_transisi:
		return
	_kunci_tombol()
	AudioManager.previous_scene_path = get_tree().current_scene.scene_file_path
	await Transisi.pindah_scene(SETTINGS_SCENE_PATH, &"")

func _on_quit_pressed() -> void:
	if Transisi.sedang_transisi:
		return
	_kunci_tombol()
	await Transisi.fade_keluar_dan_jalankan(func() -> void:
		get_tree().quit()
	, false)

func _kunci_tombol() -> void:
	for tombol in _cari_semua_button(self):
		tombol.disabled = true

func _cari_semua_button(node: Node) -> Array[BaseButton]:
	var hasil: Array[BaseButton] = []
	for child in node.get_children():
		if child is BaseButton:
			hasil.append(child)
		hasil.append_array(_cari_semua_button(child))
	return hasil
