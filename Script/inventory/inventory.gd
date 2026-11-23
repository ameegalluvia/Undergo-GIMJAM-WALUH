extends Node

signal berubah

const MAKS_SLOT := 8

var item_dipegang: DataItem = null
var daftar_item: Array[DataItem] = []
var id_terambil: Array[StringName] = []   # supaya item tidak muncul lagi setelah diambil
var id_terbuka: Array[StringName] = []   # pintu dan objek puzzle yang sudah dibuka
var ui_terbuka := false

func tambah_item(item: DataItem) -> bool:
	if item_dipegang == null:
		item_dipegang = item
	elif daftar_item.size() < MAKS_SLOT:
		daftar_item.append(item)
		_urutkan_item()
	else:
		return false   # Inventory penuh
	berubah.emit()
	return true

# Item di slot [indeks] pindah ke tangan, item di tangan (kalau ada) masuk Inventory
func tukar_dengan_tangan(indeks: int) -> void:
	if indeks < 0 or indeks >= daftar_item.size():
		return
	var item_dipilih := daftar_item[indeks]
	daftar_item.remove_at(indeks)
	if item_dipegang != null:
		daftar_item.append(item_dipegang)
	item_dipegang = item_dipilih
	_urutkan_item()
	berubah.emit()

func sedang_memegang(id_item: StringName) -> bool:
	return item_dipegang != null and item_dipegang.id == id_item

# Panggil ini kalau item yang dipegang habis dipakai
func habiskan_item_dipegang() -> void:
	item_dipegang = null
	berubah.emit()

func reset() -> void:
	item_dipegang = null
	daftar_item.clear()
	id_terambil.clear()
	id_terbuka.clear()
	berubah.emit()

func _urutkan_item() -> void:
	daftar_item.sort_custom(func(a: DataItem, b: DataItem) -> bool:
		return a.nama_tampil.to_lower() < b.nama_tampil.to_lower())
		

# BUAT SAVE MANAGER		
# Ubah isi Inventory jadi data sederhana yang bisa disimpan ke file
func ke_dictionary() -> Dictionary:
	return {
		"item_dipegang": item_dipegang.resource_path if item_dipegang else "",
		"daftar_item": daftar_item.map(func(i: DataItem) -> String: return i.resource_path),
		"id_terambil": id_terambil.map(func(s: StringName) -> String: return String(s)),
		"id_terbuka": id_terbuka.map(func(s: StringName) -> String: return String(s)),   # BARU
	}

# Pulihkan isi Inventory dari data hasil load
func dari_dictionary(data: Dictionary) -> void:
	item_dipegang = null
	daftar_item.clear()
	id_terambil.clear()
	id_terbuka.clear()
	
	for id in data.get("id_terbuka", []):
		id_terbuka.append(StringName(id))

	var path_dipegang: String = data.get("item_dipegang", "")
	if path_dipegang != "" and ResourceLoader.exists(path_dipegang):
		item_dipegang = load(path_dipegang) as DataItem

	for path in data.get("daftar_item", []):
		if ResourceLoader.exists(path):
			var item := load(path) as DataItem
			if item:
				daftar_item.append(item)

	for id in data.get("id_terambil", []):
		id_terambil.append(StringName(id))

	_urutkan_item()

	# Pemain yang sudah punya item tidak perlu petunjuk "Tekan Tab atau I" lagi
	if item_dipegang != null or not daftar_item.is_empty():
		InventoryUI.petunjuk_inventory_sudah = true

	berubah.emit()

#MEKANIK PALU DAN TIKET
# True kalau item ada di tangan atau di tas
func punya_item(id_item: StringName) -> bool:
	if sedang_memegang(id_item):
		return true
	for item in daftar_item:
		if item.id == id_item:
			return true
	return false

# Pakai item yang sedang dipegang. Dipanggil dari tombol/input "pakai".
func pakai_item_dipegang() -> void:
	if item_dipegang == null:
		return
	if item_dipegang.heal_sanity > 0.0:
		if SanityManager.pakai_obat(item_dipegang):
			InventoryUI.tampilkan_pesan("Sanity pulih +%d" % int(item_dipegang.heal_sanity), 2.0)
			habiskan_item_dipegang()
		else:
			InventoryUI.tampilkan_pesan("Tidak perlu sekarang.", 2.0)
