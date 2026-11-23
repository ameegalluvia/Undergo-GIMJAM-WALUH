class_name DialogLine
extends Resource

@export var nama: String = ""
@export_multiline var teks: String = ""
@export var potret: Texture2D          # wajah karakter, kosong = tidak ada
@export var gambar: Texture2D          # untuk cutscene gambar (lama)
@export var pakai_transisi: bool = true
@export var aksi: String = ""
@export var tunggu_aksi: bool = false
