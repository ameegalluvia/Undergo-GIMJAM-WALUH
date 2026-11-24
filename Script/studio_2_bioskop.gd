extends AdeganBase

func _ready() -> void:
	super()
	if GameProgress.tahap == GameProgress.Tahap.ACT1_STUDIO and not GameProgress.ambil_flag("cs_studio_masuk"):
		_kunci_pemain(true)
		mainkan_sekali("cs_studio_masuk", preload("res://Data/Cutscene/act1_part1studio.tres"))
	if GameProgress.ambil_flag("memori1_selesai") and not GameProgress.ambil_flag("cs_setelah_memori1"):
		_kunci_pemain(true)
		mainkan_sekali("cs_setelah_memori1", preload("res://Data/Cutscene/act1_part1after.tres"))
		
		
func mulai_kursi() -> void:
	_kunci_pemain(true)
	mainkan_sekali("cs_kursi", preload("res://Data/Cutscene/act1_part1kursi.tres"))

func selesai_cutscene() -> void:
	if GameProgress.ambil_flag("cs_kursi") and not GameProgress.ambil_flag("memori1_selesai"):
		GameProgress.set_flag("memori1_selesai")
		GameProgress.tahap = GameProgress.Tahap.ACT1_MEMORI1
		SaveManager.simpan_scene(scene_file_path)
		SanityManager.jeda_drain()   # opsional, lihat catatan
		CutsceneManager.mainkan(preload("res://Data/Cutscene/memori1.tres"))
