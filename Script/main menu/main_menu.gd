extends Control

const MENU_BGM = preload("res://assets/audio/music/ubed ganteng.mp3")
const SCENE_AWAL_PATH := "res://Scene/ruangan/lobby_bioskop.tscn"
const SETTINGS_SCENE_PATH := "res://Scene/sistem/settings.tscn"

# Ganti "Continue" dengan nama node tombol Continue di scene-mu
@onready var tombol_continue: BaseButton = find_child("Continue", true, false)

func _ready() -> void:
	AudioManager.play_music(MENU_BGM)
	_atur_tombol_continue()

func _atur_tombol_continue() -> void:
	if tombol_continue == null:
		push_warning("Tombol Continue tidak ditemukan. Cek nama node di main_menu.tscn")
		return
	
	# Cek apakah file save benar-benar ada DAN isinya valid
	var bisa_lanjut := SaveManager.save_valid()
	
	tombol_continue.disabled = not bisa_lanjut
	tombol_continue.focus_mode = Control.FOCUS_ALL if bisa_lanjut else Control.FOCUS_NONE
	tombol_continue.modulate.a = 1.0 if bisa_lanjut else 0.4  # Pudar saat terkunci


func _on_start_pressed() -> void:
	if Transisi.sedang_transisi:
		return
	_kunci_tombol()
	await Transisi.fade_keluar_dan_jalankan(func() -> void:
		AudioManager.stop_music() # <-- Sesuaikan nama fungsi stop di AudioManager kamu
		SaveManager.game_baru()
		get_tree().change_scene_to_file(SCENE_AWAL_PATH)
	, true)

func _on_continue_pressed() -> void:
	if Transisi.sedang_transisi:
		return
	if not SaveManager.save_valid():
		return
	_kunci_tombol()
	await Transisi.fade_keluar_dan_jalankan(func() -> void:
		AudioManager.stop_music() # <-- Hentikan musik main menu sebelum load scene
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
