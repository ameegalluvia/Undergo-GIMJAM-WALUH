extends AdeganBase

@onready var titik_kursi = $TitikKursi
@onready var titik_pintu_km = $TitikPintuKM
@onready var titik_pintu_keluar = $TitikPintuKeluar

func _ready() -> void:
	super()
	# Hanya jalan kalau baru dari Scene 1 dan belum pernah ditonton
	if GameProgress.tahap == GameProgress.Tahap.LOBBY and not GameProgress.ambil_flag("cs_teater"):
		fade.color.a = 0.0
		mainkan_sekali("cs_teater", preload("res://Data/Cutscene/scene2_teater.tres"))


func aksi_khusus(nama: String) -> void:
	match nama:
		"ke_kursi":
			await _jalan(johan, titik_kursi.global_position, 40.0)
			johan.last_dir = "up"
			johan.main_diam()
		"keluar_studio":
			await _jalan(johan, titik_pintu_keluar.global_position, 40.0)
			await _fade(1.0, 0.8)
			pindah("res://Scene/ruangan/lorong_bioskop.tscn", "SpawnKM", GameProgress.Tahap.TEATER)
			return
		
	overlay.aksi_selesai()
