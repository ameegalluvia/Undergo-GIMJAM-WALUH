extends AdeganBase

func _ready() -> void:
	super()
	$Tilemaps/Interior/Loker/Loker2/Kunci.item_diambil.connect(_on_kunci)


func _on_kunci(_item: DataItem) -> void:
	GameProgress.set_flag("punya_kunci_palu")
	_kunci_pemain(true)
	mainkan_sekali("cs_gudang_ketemu", preload("res://Data/Cutscene/act1_gudang_ketemu.tres"))


func selesai_cutscene() -> void:
	if GameProgress.ambil_flag("cs_gudang_ketemu"):
		GameProgress.tahap = GameProgress.Tahap.ACT1_TEMBOK
		SaveManager.simpan_scene(scene_file_path)
