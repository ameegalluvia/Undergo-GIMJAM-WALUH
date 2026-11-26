extends Node

const FILE_SAVE := "user://save.json"

var titik_respawn: String = ""   # nama Marker2D di scene tersimpan, kosong = default


func set_titik_respawn(nama: String) -> void:
	titik_respawn = nama
	# ikut tersimpan di file
	GameProgress.set_flag("titik_respawn", nama)
	

func ada_save() -> bool:
	return FileAccess.file_exists(FILE_SAVE)


# True kalau ada save yang bisa dimuat (file ada, isinya benar, scene-nya ada)
func save_valid() -> bool:
	var data: Dictionary = _baca()
	if data.is_empty():
		return false
	var path: String = String(data.get("scene", ""))
	return path != "" and ResourceLoader.exists(path)


# ---------- Simpan ----------
const SCENE_TERLARANG := [
	"res://Scene/sistem/main_menu.tscn", # sesuaikan dengan path main menu kamu
	"res://Scene/sistem/settings.tscn"
]

func simpan_scene(scene_path: String = "") -> void:
	if scene_path == "":
		scene_path = get_tree().current_scene.scene_file_path
	
	# Tolak penyimpanan jika sedang di Main Menu atau Settings
	if scene_path == "" or scene_path in SCENE_TERLARANG:
		return

	var data := {
		"scene": scene_path,
		"tahap": GameProgress.tahap,
		"flag": GameProgress.flag,
		"sanity": SanityManager.nilai,
		"sanity_aktif": SanityManager.aktif,
		"inventory": Inventory.ke_dictionary(),
	}

	var f := FileAccess.open(FILE_SAVE, FileAccess.WRITE)
	if f == null:
		push_warning("Gagal menyimpan: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(data))


# ---------- Muat ----------
func _baca() -> Dictionary:
	if not ada_save():
		return {}
	var f := FileAccess.open(FILE_SAVE, FileAccess.READ)
	if f == null:
		return {}
	var hasil = JSON.parse_string(f.get_as_text())
	return hasil if hasil is Dictionary else {}


func lanjutkan(sanity_minimum: float = 0.0) -> void:
	var data := _baca()
	if data.is_empty() or String(data.get("scene", "")) == "":
		return

	GameProgress.tahap = int(data.get("tahap", 0))
	GameProgress.flag = data.get("flag", {})
	Inventory.dari_dictionary(data.get("inventory", {}))

	SanityManager.johan_glitch = false
	SanityManager.dijeda = false
	SanityManager.set_nilai(maxf(float(data.get("sanity", SanityManager.MAKS)), sanity_minimum))
	if data.get("sanity_aktif", false):
		SanityManager.aktifkan()
	else:
		SanityManager.nonaktifkan()

	var path: String = data["scene"]
	if not ResourceLoader.exists(path):
		push_warning("Scene save tidak ditemukan: " + path)
		return
	get_tree().change_scene_to_file(path)


# Dipanggil saat mati karena sanity habis
func respawn() -> void:
	if not ada_save():
		get_tree().reload_current_scene()
		return
	lanjutkan(60.0)
	if GameProgress.tahap >= GameProgress.Tahap.TERKUNCI:
		SanityManager.aktifkan()
		SanityManager.lanjut_drain()
	GameProgress.set_flag("dari_respawn", true)   # setelah lanjutkan(), karena lanjutkan mengisi ulang flag  # kembali dengan sanity minimal 60 supaya tidak mati berulang


# ---------- Game baru ----------
func game_baru() -> void:
	if ada_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE_SAVE))
	GameProgress.reset()
	Inventory.reset()
	SanityManager.reset()
	SanityManager.nonaktifkan()
