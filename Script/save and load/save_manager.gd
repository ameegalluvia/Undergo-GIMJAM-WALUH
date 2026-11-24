extends Node

const FILE_SAVE := "user://save.json"


func ada_save() -> bool:
	return FileAccess.file_exists(FILE_SAVE)


# ---------- Simpan ----------
func simpan_scene(scene_path: String = "") -> void:
	if scene_path == "":
		scene_path = get_tree().current_scene.scene_file_path

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


func lanjutkan() -> void:
	var data := _baca()
	if data.is_empty() or String(data.get("scene", "")) == "":
		return

	GameProgress.tahap = int(data.get("tahap", 0))   # JSON menyimpan angka sebagai float
	GameProgress.flag = data.get("flag", {})
	Inventory.dari_dictionary(data.get("inventory", {}))

	SanityManager.set_nilai(float(data.get("sanity", SanityManager.MAKS)))
	if data.get("sanity_aktif", false):
		SanityManager.aktifkan()
	else:
		SanityManager.nonaktifkan()

	var path: String = data["scene"]
	if not ResourceLoader.exists(path):
		push_warning("Scene save tidak ditemukan: " + path)
		return
	Transisi.pindah_scene(path, &"")   # tanpa titik tujuan, Johan di posisi default scene


# ---------- Game baru ----------
func game_baru() -> void:
	if ada_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE_SAVE))
	GameProgress.reset()
	Inventory.reset()
	SanityManager.reset()
	SanityManager.nonaktifkan()
