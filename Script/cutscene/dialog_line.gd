class_name DialogLine
extends Resource

@export var nama: String = ""
@export_multiline var teks: String = ""
@export var potret: Texture2D          # wajah karakter, kosong = tidak ada
@export var gambar: Texture2D          # untuk cutscene gambar (lama)
@export var pakai_transisi: bool = true
@export var aksi: String = ""
@export var tunggu_aksi: bool = false
@export_group("Audio")
@export var suara_tambahan: AudioStream            # kosong = tidak ada
@export var volume_tambahan_db: float = 0.0
@export var suara_teks_khusus: AudioStream         # kosong = pakai blip bawaan
@export var backsound: AudioStream        # kosong = lanjutkan yang sedang main
@export var volume_backsound_db: float = 0.0
@export var stop_backsound := false       # centang = hentikan backsound di baris ini
