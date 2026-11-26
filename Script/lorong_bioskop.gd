extends AdeganBase

# ---------- Referensi ----------
@onready var spawn_km: Marker2D = $SpawnKm
@onready var bayangan_mulai: Marker2D = $BayanganMulai
@onready var bayangan_akhir: Marker2D = $BayanganAkhir
@onready var bayangan_masuk1: Marker2D = $BayanganMasuk1
@onready var bayangan_studio: Marker2D = $BayanganMasuk2         # ACT 1: pintu studio baru

@onready var area_sadar: Area2D = $AreaSadar
@onready var area_pintu_keluar: Area2D = $Pintu/PintuLobbyBioskop/PintuKeLobbyBioskop
@onready var area_bayangan: Area2D = $AreaBayangan
@onready var area_bayangan2: Area2D = $AreaBayangan2              # ACT 1: pemicu "Ah, itu dia!"

@onready var pintu_lobby = $Pintu/PintuLobbyBioskop/PintuKeLobbyBioskop
@onready var pintu_studio5 = $Pintu/PintuStudio/PintuStudio1/PintuKeStudio1
@onready var pintu_km = $Pintu/PintuKamarMandi/Kamarmandi1/PintuKamarmandi1Cowo/PintuKeKamamandi1Cowo
@onready var pintu_keluar = $Pintu/PintuLobbyBioskop/PintuKeLobbyBioskop
@onready var pintu_studio_baru = $Pintu/PintuStudio/PintuStudio2/PintuKeStudio2             # ACT 1

@onready var gelap: CanvasModulate = $Shaders   # visible = gelap, hidden = terang
@onready var senter: PointLight2D = $Player/Senter/Cahaya
@onready var bayangan: AnimatedSprite2D = $Bayangan

@export var musik_gedor: AudioStream
@export var durasi_fade_musik := 1.0


func _ready() -> void:
	super()
	_atur_pintu()
	_atur_cahaya()
	_mulai_adegan()
	$Puzzle/PuzzlePoster.terbuka.connect(func(dengan_efek: bool):
		if dengan_efek:
			_kunci_pemain(true)
			mainkan_sekali("cs_tembok_hancur", preload("res://Data/Cutscene/act1_tembol_hancur.tres")))


# ---------- Cahaya ----------	
func _atur_cahaya() -> void:
	var mati: bool = GameProgress.ambil_flag("listrik_mati")
	gelap.visible = mati
	senter.enabled = mati
	if GameProgress.tahap != GameProgress.Tahap.ACT1_KEJAR:
		bayangan.visible = false


# ---------- Kondisi pintu per tahap ----------
func _atur_pintu() -> void:
	var t: int = GameProgress.tahap
	var T = GameProgress.Tahap

	# Balik ke lobby: selalu terkunci
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

	# Pintu keluar: terkunci sepanjang Act 0 dan Act 1 awal
	pintu_keluar.terkunci = true
	if t < T.TERKUNCI:
		pintu_keluar.pesan_terkunci = "Aku harus menemukan obatku dulu."
	else:
		pintu_keluar.pesan_terkunci = "Kekunci..."

	# ACT 1: studio baru terbuka setelah bayangan masuk ke sana
	pintu_studio_baru.terkunci = t < T.ACT1_STUDIO
	pintu_studio_baru.pesan_terkunci = "Bukan tujuanku sekarang."

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
	area_bayangan.body_entered.connect(_on_area_bayangan)
	area_bayangan.monitoring = false
	area_bayangan2.body_entered.connect(_on_area_bayangan2)
	area_bayangan2.monitoring = false

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
			mainkan_sekali("cs_pulang", preload("res://Data/Cutscene/scene3_pulang.tres"))

	# Scene 4: obat sudah ketemu, pemain menuju pintu keluar
	elif t == T.TERKUNCI:
		if not GameProgress.ambil_flag("cs_listrik"):
			area_pintu_keluar.monitoring = true
		elif not GameProgress.ambil_flag("cs_bayangan"):
			area_bayangan.monitoring = true   # Continue setelah listrik mati

	# ACT 1: Johan mencari orang tadi
	elif t == T.ACT1_MULAI:
		if not GameProgress.ambil_flag("cs_act1_mulai"):
			_kunci_pemain(true)
			mainkan_sekali("cs_act1_mulai", preload("res://Data/Cutscene/act1_part1awal.tres"))
		elif not GameProgress.ambil_flag("cs_act1_bayangan"):
			area_bayangan2.monitoring = true   # Continue


# ---------- Pemicu ----------
func _on_area_sadar(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if GameProgress.ambil_flag("cs_obat_hilang"):
		return
	area_sadar.set_deferred("monitoring", false)
	_kunci_pemain(true)
	mainkan_sekali("cs_obat_hilang", preload("res://Data/Cutscene/Obathilang.tres"))


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


func _on_area_bayangan2(body: Node) -> void:   # ACT 1
	if not body.is_in_group("player"):
		return
	if GameProgress.ambil_flag("cs_act1_bayangan"):
		return
	area_bayangan2.set_deferred("monitoring", false)
	_kunci_pemain(true)
	mainkan_sekali("cs_act1_bayangan", preload("res://Data/Cutscene/act1_part1bayangan.tres"))


# ---------- Setelah dialog selesai ----------
func selesai_cutscene() -> void:
	var T = GameProgress.Tahap
	if GameProgress.ambil_flag("cs_tembok_hancur") and not GameProgress.ambil_flag("tembok_dipindah"):
		GameProgress.set_flag("tembok_dipindah")
		await _fade(1.0, 0.5)
		johan.global_position = $SpawnSetelahTembok.global_position
		johan.last_dir = "down"
		johan.main_diam()
		await _fade(0.0, 0.5)
		GameProgress.tahap = GameProgress.Tahap.ACT1_KONTROL_ROOM
		SaveManager.simpan_scene(scene_file_path)
		_kunci_pemain(false)
		return
	# ACT 1 Part 2: pengejaran
	if GameProgress.tahap == T.ACT1_KEJAR:
		$Kejar.lanjut_setelah_dialog()
		return

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

	# Setelah bagian 1 Scene 4: pemain bebas, pemicu bayangan aktif
	if GameProgress.ambil_flag("cs_listrik") and not GameProgress.ambil_flag("cs_bayangan"):
		area_bayangan.set_deferred("monitoring", true)
		return

	# Setelah bagian 2 Scene 4: Act 0 selesai, Act 1 dimulai
	if GameProgress.ambil_flag("cs_bayangan") and GameProgress.tahap == T.TERKUNCI:
		GameProgress.tahap = T.ACT1_MULAI                 # ACT 1
		SanityManager.set_nilai(80.0)
		SanityManager.aktifkan()                         # bar muncul, drain mulai
		SaveManager.simpan_scene(scene_file_path)
		_kunci_pemain(true)
		await _fade(1.0, 1.5)                             # "Act 0 Ends"
		await _fade(0.0, 1.0)
		mainkan_sekali("cs_act1_mulai", preload("res://Data/Cutscene/act1_part1awal.tres"))
		return

	# ACT 1: setelah "Kemana perginya orang itu?", pemain bebas mencari
	if GameProgress.ambil_flag("cs_act1_mulai") and not GameProgress.ambil_flag("cs_act1_bayangan"):
		area_bayangan2.set_deferred("monitoring", true)
		return

	# ACT 1: setelah bayangan masuk studio, buka pintu studio baru
	if GameProgress.ambil_flag("cs_act1_bayangan") and GameProgress.tahap == T.ACT1_MULAI:
		GameProgress.tahap = T.ACT1_STUDIO
		pintu_studio_baru.terkunci = false
		SaveManager.simpan_scene(scene_file_path)
		
		
	if GameProgress.ambil_flag("cs_palu_terkunci") and GameProgress.tahap < GameProgress.Tahap.ACT1_GUDANG:
		GameProgress.tahap = GameProgress.Tahap.ACT1_GUDANG
		SaveManager.simpan_scene(scene_file_path)
	if GameProgress.ambil_flag("cs_tembok_hancur"):
		GameProgress.set_flag("titik_respawn", "SpawnSetelahTembok")
		GameProgress.tahap = GameProgress.Tahap.ACT1_TEMBOK + 1
		SaveManager.simpan_scene(scene_file_path)
		
	if GameProgress.ambil_flag("tembok_dipindah") and has_node("SpawnSetelahTembok"):
		johan.global_position = $SpawnSetelahTembok.global_position



# ---------- Aksi dari dialog ----------
func aksi_khusus(nama: String) -> void:
	match nama:
		"gedor":
			if musik_gedor != null:
				AudioManager.play_music(musik_gedor, durasi_fade_musik)
			for i in 4:
				johan.global_position.x += 1.0
				await get_tree().create_timer(0.08).timeout
				johan.global_position.x -= 1.0
				await get_tree().create_timer(0.08).timeout
				
		"musik_berhenti":
			AudioManager.fade_out_music(durasi_fade_musik)

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
			await _gerak_bayangan(bayangan_mulai.global_position, bayangan_akhir.global_position)

		"bayangan_masuk_studio":   # ACT 1
			await _gerak_bayangan(bayangan_masuk1.global_position, bayangan_studio.global_position)
			
		"bayangan_kabur":
			await $Kejar.bayangan_kabur()

	overlay.aksi_selesai()


# ---------- Bantu: bayangan berjalan dari titik ke titik ----------
func _gerak_bayangan(awal: Vector2, tujuan: Vector2) -> void:
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
	
