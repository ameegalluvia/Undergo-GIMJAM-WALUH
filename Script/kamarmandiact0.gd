extends AdeganBase

@onready var titik_stall = $TitikStall

func _ready() -> void:
	super()
	if GameProgress.tahap == GameProgress.Tahap.CARI_OBAT and not GameProgress.ambil_flag("cs_ketemu"):
		_kunci_pemain(true)
		await _jalan(johan, titik_stall.global_position)
		mainkan_sekali("cs_ketemu", preload("res://Data/Cutscene/scene3_ketemu.tres"))


func selesai_cutscene() -> void:
	if GameProgress.ambil_flag("cs_ketemu") and GameProgress.tahap == GameProgress.Tahap.CARI_OBAT:
		GameProgress.tahap = GameProgress.Tahap.TERKUNCI
		# pintu keluar di lorong dibuka kuncinya oleh scene lorong saat tahap TERKUNCI
		SaveManager.simpan_scene(scene_file_path)
