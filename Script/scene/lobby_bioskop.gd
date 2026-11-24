extends AdeganBase

@onready var npc1 = $Npc1
@onready var npc2 = $Npc2
@onready var titik_masuk = $TitikMasuk
@onready var titik_tengah = $TitikTengah
@onready var titik_maju = $TitikKonter
@onready var titik_keluar = $TitikKeluar
@onready var area_konter = $AreaKonter
@onready var pintu_teater = $PintuKeLorong


func _ready() -> void:
	super()
	pintu_teater.terkunci = not GameProgress.ambil_flag("cs_lobby")
	if GameProgress.ambil_flag("cs_lobby"):
		npc1.visible = false
		npc2.visible = false
		return

	_kunci_pemain(true)
	johan.global_position = titik_masuk.global_position
	await get_tree().create_timer(0.5).timeout
	await _jalan(johan, titik_tengah.global_position)
	johan.last_dir = "up"
	johan.main_diam()
	mainkan_sekali("cs_lobby", preload("res://Data/Cutscene/adeganbioskop1.tres"))


func selesai_cutscene() -> void:
	pintu_teater.terkunci = false


func aksi_khusus(nama: String) -> void:
	match nama:
		"npc_keluar":
			_jalan_hilang(npc1, titik_keluar.global_position)
			await _jalan_hilang(npc2, titik_keluar.global_position + Vector2(60, 0))
		"kontrol_ke_konter":
			await _tuntun_ke(area_konter)
		"ambil_tiket":
			var tiket: DataItem = preload("res://Data/Items/tiket_bioskop.tres")
			if Inventory.tambah_item(tiket):
				InventoryUI.umumkan_item_diambil(tiket)
		"auto_maju":
			await _jalan(johan, titik_maju.global_position)
	overlay.aksi_selesai()


func _jalan_hilang(node: Node2D, titik: Vector2) -> void:
	await _jalan(node, titik)
	node.visible = false
