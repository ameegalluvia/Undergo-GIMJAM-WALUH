extends AdeganBase

@onready var pintu_keluar = $PintuLorongBioskop/PintuKeLorongBioskop  # sesuaikan nama pintu kembali ke lorong


func _ready() -> void:
	super()
	await get_tree().process_frame
	var daftar := get_tree().get_nodes_in_group("boneka")
	if not GameProgress.flag.has("boneka_kayu") and not daftar.is_empty():
		GameProgress.set_flag("boneka_kayu", String(daftar.pick_random().name))
	var nama_kayu: String = str(GameProgress.ambil_flag("boneka_kayu", ""))
	for b in daftar:
		b.berisi_kayu = (String(b.name) == nama_kayu)
		b.dihancurkan.connect(_on_boneka)
	var T = GameProgress.Tahap
	var t: int = GameProgress.tahap

	# Kembali dari Memori 2 berarti memori sudah selesai
	if t == T.ACT1_MEMORI2 and GameProgress.ambil_flag("cs_s3_bayangan"):
		GameProgress.set_flag("memori2_selesai")
		SanityManager.lanjut_drain()

	# Pintu keluar terkunci sampai bagian studio selesai
	pintu_keluar.terkunci = GameProgress.tahap < T.ACT1_KONTROL
	pintu_keluar.pesan_terkunci = "Johan: Aku belum selesai di sini."

	# Adegan sesuai tahap
	if t == T.ACT1_STUDIO3 and not GameProgress.ambil_flag("cs_s3_masuk"):
		GameProgress.tahap = T.ACT1_BONEKA
		_kunci_pemain(true)
		mainkan_sekali("cs_s3_masuk", preload("res://Data/Cutscene/act1_s3_masuk.tres"))
	elif GameProgress.ambil_flag("memori2_selesai") and not GameProgress.ambil_flag("cs_s3_setelah"):
		_kunci_pemain(true)
		mainkan_sekali("cs_s3_setelah", preload("res://Data/Cutscene/act1_s3_setelah.tres"))

	# Boneka dibuat oleh BonekaDariTile (harus di atas node lain), tunggu satu frame
	await get_tree().process_frame
	_siapkan_boneka()


# ---------- Boneka ----------
func _siapkan_boneka() -> void:
	var daftar := get_tree().get_nodes_in_group("boneka")
	print("siapkan_boneka, jumlah di grup: ", daftar.size())
	if daftar.is_empty():
		return

	# Pilih satu boneka berisi kayu, simpan agar konsisten saat Continue
	if not GameProgress.flag.has("boneka_kayu"):
		GameProgress.set_flag("boneka_kayu", String(daftar.pick_random().name))
	var nama_kayu: String = str(GameProgress.ambil_flag("boneka_kayu", ""))

	for b in daftar:
		b.berisi_kayu = (String(b.name) == nama_kayu)
		if not b.dihancurkan.is_connected(_on_boneka):
			b.dihancurkan.connect(_on_boneka)


func _on_boneka(b) -> void:
	print("hancur: ", b.name, " berisi_kayu: ", b.berisi_kayu, " dapat_kayu: ", GameProgress.ambil_flag("dapat_kayu"))
	if not b.berisi_kayu:
		return
	var kayu: DataItem = preload("res://Data/Items/kayu.tres")
	if Inventory.tambah_item(kayu):
		InventoryUI.umumkan_item_diambil(kayu)
	GameProgress.set_flag("dapat_kayu")
	_kunci_pemain(true)
	mainkan_sekali("cs_s3_bayangan", preload("res://Data/Cutscene/act1_s3_kayu.tres"))


# ---------- Setelah dialog selesai ----------
func selesai_cutscene() -> void:
	var T = GameProgress.Tahap

	# Setelah "Jangan sembunyi, keluarlah!": pemain bebas menghancurkan boneka
	if GameProgress.ambil_flag("cs_s3_masuk") and not GameProgress.ambil_flag("cs_s3_bayangan"):
		_kunci_pemain(false)
		SaveManager.simpan_scene(scene_file_path)
		return

	# Setelah dialog kayu dan bayangan: masuk Memori 2
	if GameProgress.ambil_flag("cs_s3_bayangan") and not GameProgress.ambil_flag("memori2_selesai"):
		GameProgress.tahap = T.ACT1_MEMORI2
		SaveManager.simpan_scene(scene_file_path)
		SanityManager.jeda_drain()
		CutsceneManager.mainkan(preload("res://Data/Cutscene/memori2.tres"))   # Scene Berikutnya: studio3.tscn
		return

	# Setelah memori: tujuan baru (ruang kontrol), pintu terbuka
	if GameProgress.ambil_flag("cs_s3_setelah"):
		GameProgress.tahap = T.ACT1_KONTROL
		pintu_keluar.terkunci = false
		SaveManager.simpan_scene(scene_file_path)
		_kunci_pemain(false)


# ---------- Aksi dialog (belum ada untuk studio 3) ----------
func aksi_khusus(_nama: String) -> void:
	overlay.aksi_selesai()
