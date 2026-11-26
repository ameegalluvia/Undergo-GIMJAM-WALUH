extends AdeganBase

@onready var tutup = $Tilemaps/Interior/Saklar/Tutup
@onready var tanpa = $Tilemaps/Interior/Saklar/TanpaSaklar
@onready var mati = $Tilemaps/Interior/Saklar/BukaMati
@onready var loker = $Tilemaps/Interior/Loker1
@onready var komputer = $Komputer


func _ready() -> void:
	super()
	GameProgress.tahap = max(GameProgress.tahap, GameProgress.Tahap.ACT1_KONTROL_ROOM)

	_atur_saklar()
	_atur_loker()

	tutup.terbuka.connect(_on_tutup)
	tanpa.terbuka.connect(_on_kayu_terpasang)
	mati.terbuka.connect(_on_saklar_aktif)
	if loker.has_signal("item_diambil"):
		loker.item_diambil.connect(_on_kaset)
	komputer.dipakai.connect(_on_komputer)


# ---------- Kondisi awal (aman untuk Continue) ----------
func _atur_saklar() -> void:
	var s1: bool = Inventory.id_terbuka.has(tutup.id_puzzle)
	var s2: bool = Inventory.id_terbuka.has(tanpa.id_puzzle)
	var s3: bool = Inventory.id_terbuka.has(mati.id_puzzle)
	tutup.monitoring = not s1
	tanpa.monitoring = s1 and not s2
	mati.monitoring = s2 and not s3


func _atur_loker() -> void:
	var terbuka: bool = GameProgress.ambil_flag("cs_saklar")
	loker.monitoring = terbuka and not GameProgress.ambil_flag("cs_kaset")



# ---------- Handler puzzle ----------
func _on_tutup(dengan_efek: bool) -> void:
	if dengan_efek:
		tanpa.set_deferred("monitoring", true)


func _on_kayu_terpasang(dengan_efek: bool) -> void:
	if not dengan_efek:
		return
	_kunci_pemain(true)
	mainkan_sekali("cs_kayu_terpasang", preload("res://Data/Cutscene/act1_saklar_kayu.tres"))


func _on_saklar_aktif(dengan_efek: bool) -> void:
	if not dengan_efek:
		return
	_kunci_pemain(true)
	mainkan_sekali("cs_saklar", preload("res://Data/Cutscene/act1_saklar.tres"))


func _on_kaset(_item: DataItem) -> void:
	GameProgress.set_flag("punya_kaset")
	_kunci_pemain(true)
	mainkan_sekali("cs_kaset", preload("res://Data/Cutscene/act1_kaset.tres"))


func _on_komputer() -> void:
	_kunci_pemain(true)
	GameProgress.tahap = GameProgress.Tahap.ACT1_ENDING
	SanityManager.jeda_drain()
	SaveManager.simpan_scene(scene_file_path)
	# memori3.tres: 2 gambar memori 3, lalu ending (Scene Berikutnya sesuai rancanganmu)
	CutsceneManager.mainkan(preload("res://Data/Cutscene/memori3.tres"))


# ---------- Setelah dialog selesai ----------
func selesai_cutscene() -> void:
	# Kayu terpasang: saklar aktif bisa dipakai
	if GameProgress.ambil_flag("cs_kayu_terpasang") and not GameProgress.ambil_flag("cs_saklar"):
		mati.set_deferred("monitoring", true)
		SaveManager.simpan_scene(scene_file_path)
		_kunci_pemain(false)
		return

	# Saklar aktif: loker terbuka sedikit dan bisa diinteraksi
	if GameProgress.ambil_flag("cs_saklar") and not GameProgress.ambil_flag("cs_kaset"):
		GameProgress.tahap = GameProgress.Tahap.ACT1_SAKLAR
		_atur_loker()
		SaveManager.simpan_scene(scene_file_path)
		_kunci_pemain(false)
		return

	# Kaset didapat: komputer bisa dipakai
	if GameProgress.ambil_flag("cs_kaset"):
		GameProgress.tahap = GameProgress.Tahap.ACT1_KASET
		SaveManager.simpan_scene(scene_file_path)
		_kunci_pemain(false)


# ---------- Aksi dialog ----------
func aksi_khusus(nama: String) -> void:
	match nama:
		"berbalik":
			johan.last_dir = "down"
			johan.main_diam()
		"jeda":
			await get_tree().create_timer(1.5).timeout
	overlay.aksi_selesai()
