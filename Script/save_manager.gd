extends Node

const FILE_SAVE := "user://save.json"

var data := {
	"scene": "",
	"flag": {},
}


func ada_save() -> bool:
	return FileAccess.file_exists(FILE_SAVE)


func simpan_scene(scene_path: String) -> void:
	data["scene"] = scene_path
	_tulis()


func set_flag(nama: String, nilai = true) -> void:
	data["flag"][nama] = nilai
	_tulis()


func ambil_flag(nama: String, default = false):
	return data["flag"].get(nama, default)


# Dipanggil setelah Inventory berubah (ambil item, swap) supaya langsung tersimpan
func simpan_inventory() -> void:
	_tulis()


func _tulis() -> void:
	data["inventory"] = Inventory.ke_dictionary()   # Inventory ikut tertulis
	var f := FileAccess.open(FILE_SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))


func muat() -> bool:
	if not ada_save():
		return false
	var f := FileAccess.open(FILE_SAVE, FileAccess.READ)
	var hasil = JSON.parse_string(f.get_as_text())
	if hasil is Dictionary:
		data = hasil
		return true
	return false


func lanjutkan() -> void:
	if muat() and not data["scene"].is_empty():
		# Pulihkan Inventory SEBELUM pindah scene, karena pickup
		# mengecek id_terambil di _ready()
		Inventory.dari_dictionary(data.get("inventory", {}))
		get_tree().change_scene_to_file(data["scene"])


func game_baru() -> void:
	if ada_save():
		DirAccess.remove_absolute(FILE_SAVE)
	data = {"scene": "", "flag": {}}
	Inventory.reset()   # kosongkan Inventory dari run sebelumnya
