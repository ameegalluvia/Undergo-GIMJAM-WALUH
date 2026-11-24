extends AdeganBase

# ---------- Referensi ----------
@onready var spawn_km: Marker2D = $SpawnKm
@onready var bayangan_mulai: Marker2D = $BayanganMulai
@onready var bayangan_akhir: Marker2D = $BayanganAkhir

@onready var area_sadar: Area2D = $AreaSadar
@onready var area_pintu_keluar: Area2D = $Pintu/PintuLobbyBioskop/PintuKeLobbyBioskop
@onready var area_bayangan: Area2D = $AreaBayangan

@onready var pintu_lobby = $Pintu/PintuLobbyBioskop/PintuKeLobbyBioskop
@onready var pintu_studio5 = $Pintu/PintuStudio/PintuStudio1/PintuKeStudio1
@onready var pintu_km = $Pintu/PintuKamarMandi/Kamarmandi1/PintuKamarmandi1Cowo/PintuKeKamamandi1Cowo
@onready var pintu_keluar = $Pintu/PintuLobbyBioskop/PintuKeLobbyBioskop

@onready var gelap: CanvasModulate = $Shaders   # visible = gelap, hidden = terang
@onready var senter: PointLight2D = $Player/Senter
@onready var bayangan: AnimatedSprite2D = $Bayangan


func _ready() -> void:
	super()
	_atur_pintu()
	_atur_cahaya()
	_mulai_adegan()


# ---------- Cahaya ----------
func _atur_cahaya() -> void:
	var mati: bool = GameProgress.ambil_flag("listrik_mati")
	gelap.visible = mati
	senter.enabled = mati
	bayangan.visible = false


# ---------- Kondisi pintu per tahap ----------
func _atur_pintu() -> void:
	var t: int = GameProgress.tahap
	var T = GameProgress.Tahap

	# Balik ke lobby: selalu terkunci di Act 0
	pintu_lobby.terkunci = true
	pintu_lobby.pesan_terkunci = "Johan: Aku harus menuju ke teater 1"

	# Studio 5: terkunci setelah Johan menonton
	if t >= T.TEATER:
		pintu_studio5.terkunci = true
		pintu_studio5.item_dibutuhkan = null
		pintu_studio5.pesan_terkunci = "Dikunci..."

	# Kamar mandi: terbuka mulai setelah Studio 5
	pintu_km.terkunci = t < T.TEATER
	pintu_km.pesan_terkunci = "Bukan tujuanku sekarang."

	# Pintu keluar: terkunci sepanjang Act 0
	pintu_keluar.terkunci = true
	if t < T.TERKUNCI:
		pintu_keluar.pesan_terkunci = "Aku harus menemukan obatku dulu."
	else:
		pintu_keluar.pesan_terkunci = "Kekunci..."

	# Pintu lain (studio 1-4, ruangan lain): masukkan ke grup lewat Inspector
	for p in get_tree().get_nodes_in_group("pintu_terkunci_act0"):
		p.terkunci = true
		p.pesan_terkunci = "Bukan studio yang kutuju."


# ---------- Adegan sesuai tahap ----------
func _mulai_adegan() -> void:
	var t: int = GameProgress.tahap
	var T = GameProgress.Tahap

	area_sadar.body_entered.connect(_on_area_sadar)
	area_sadar.monitoring = false
	area_pintu_keluar.body_entered.connect(_on_area_pintu_keluar)
	area_pintu_keluar.monitoring = false

	# Scene 3: Johan di depan kamar mandi, bilang mau pulang
	if t == T.TEATER and not GameProgress.ambil_flag("cs_obat_hilang"):
		if GameProgress.ambil_flag("cs_pulang"):
			area_sadar.monitoring = true   # Continue setelah dialog "pulang"
		else:
			_kunci_pemain(true)
			johan.global_position = spawn_km.global_position
			johan.last_dir = "down"
			johan.main_diam()
			await get_tree().create_timer(0.5).timeout
			mainkan_sekali("cs_pulang", preload("res://Data/Cutscene/Adegan3.tres"))

	# Scene 4: obat sudah ketemu, pemain menuju pintu keluar
	elif t == T.TERKUNCI and not GameProgress.ambil_flag("cs_listrik"):
		area_pintu_keluar.monitoring = true

	# Continue setelah listrik mati tapi sebelum bayangan
	area_bayangan.body_entered.connect(_on_area_bayangan)
	area_bayangan.monitoring = false
	if t == T.TERKUNCI and GameProgress.ambil_flag("cs_listrik") and not GameProgress.ambil_flag("cs_bayangan"):
		area_bayangan.monitoring = true



# ---------- Pemicu ----------
func _on_area_sadar(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if GameProgress.ambil_flag("cs_obat_hilang"):
		return
	area_sadar.set_deferred("monitoring", false)
	_kunci_pemain(true)
	mainkan_sekali("cs_obat_hilang", preload("res://Data/Cutscene/obathilang.tres"))


func _on_area_pintu_keluar(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if GameProgress.ambil_flag("cs_listrik"):
		return
	area_pintu_keluar.set_deferred("monitoring", false)
	_kunci_pemain(true)
	mainkan_sekali("cs_listrik", preload("res://Data/Cutscene/scene4_listrik.tres"))

func _on_area_bayangan(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if GameProgress.ambil_flag("cs_bayangan"):
		return
	area_bayangan.set_deferred("monitoring", false)
	_kunci_pemain(true)
	mainkan_sekali("cs_bayangan", preload("res://Data/Cutscene/scene4_bayangan.tres"))
	
# ---------- Setelah dialog selesai ----------
func selesai_cutscene() -> void:
	var T = GameProgress.Tahap

	# Setelah "ayo pulang": pemain bebas, pemicu aktif
	if GameProgress.ambil_flag("cs_pulang") and not GameProgress.ambil_flag("cs_obat_hilang"):
		area_sadar.set_deferred("monitoring", true)
		return

	# Setelah sadar obat hilang: pemain mencari obat
	if GameProgress.ambil_flag("cs_obat_hilang") and GameProgress.tahap == T.TEATER:
		GameProgress.tahap = T.CARI_OBAT
		pintu_studio5.terkunci = true
		pintu_studio5.item_dibutuhkan = null
		pintu_studio5.pesan_terkunci = "Dikunci..."
		pintu_km.terkunci = false
		SaveManager.simpan_scene(scene_file_path)
		return

	# Setelah Scene 4: Act 0 selesai
		# Setelah bagian 1 Scene 4: pemain bebas, pemicu bayangan aktif
	if GameProgress.ambil_flag("cs_listrik") and not GameProgress.ambil_flag("cs_bayangan"):
		area_bayangan.set_deferred("monitoring", true)
		return

	# Setelah bagian 2: Act 0 selesai
	if GameProgress.ambil_flag("cs_bayangan") and GameProgress.tahap == T.TERKUNCI:
		GameProgress.tahap = T.ACT0_SELESAI
		SaveManager.simpan_scene(scene_file_path)
		_kunci_pemain(true)
		await _fade(1.0, 1.5)
		print("Act 0 Ends")


# ---------- Aksi dari dialog ----------
func aksi_khusus(nama: String) -> void:
	match nama:
		"gedor":
			for i in 4:
				johan.global_position.x += 1.0
				await get_tree().create_timer(0.08).timeout
				johan.global_position.x -= 1.0
				await get_tree().create_timer(0.08).timeout

		"listrik_mati":
			GameProgress.set_flag("listrik_mati")
			for i in 2:   # kedip singkat sebelum gelap
				gelap.visible = true
				await get_tree().create_timer(0.07).timeout
				gelap.visible = false
				await get_tree().create_timer(0.1).timeout
			gelap.visible = true
			await get_tree().create_timer(0.4).timeout

		"senter_nyala":
			senter.enabled = true

		"bayangan_lewat":
			var awal: Vector2 = bayangan_mulai.global_position
			var tujuan: Vector2 = bayangan_akhir.global_position
			bayangan.global_position = awal
			bayangan.visible = true
			var arah := tujuan - awal
			var sisi := "right" if arah.x > 0 else "left"
			if abs(arah.y) > abs(arah.x):
				sisi = "down" if arah.y > 0 else "up"
			if bayangan.sprite_frames.has_animation("walk_" + sisi):
				bayangan.play("walk_" + sisi)
			var tw := create_tween()
			tw.tween_property(bayangan, "global_position", tujuan, arah.length() / 90.0)
			await tw.finished
			bayangan.visible = false

	overlay.aksi_selesai()
