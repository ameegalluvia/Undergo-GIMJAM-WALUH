extends AdeganBase

@onready var titik_stall = $TitikStall


func _ready() -> void:
	super()
	if GameProgress.tahap == GameProgress.Tahap.CARI_OBAT and not GameProgress.ambil_flag("cs_ketemu"):
		_kunci_pemain(true)
		await _jalan(johan, titik_stall.global_position)
		mainkan_sekali("cs_ketemu", preload("res://Data/Cutscene/scene3_ketemu.tres"))


func aksi_khusus(nama: String) -> void:
	match nama:
		"ambil_obat":
			var obat: DataItem = preload("res://Data/Items/obat.tres")
			if Inventory.tambah_item(obat):
				InventoryUI.umumkan_item_diambil(obat)
			else:
				InventoryUI.tampilkan_pesan("Inventory penuh!", 2.0)
	overlay.aksi_selesai()


func selesai_cutscene() -> void:
	if GameProgress.ambil_flag("cs_ketemu") and GameProgress.tahap == GameProgress.Tahap.CARI_OBAT:
		GameProgress.tahap = GameProgress.Tahap.TERKUNCI
		SaveManager.simpan_scene(scene_file_path)
