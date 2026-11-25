extends Node

enum Tahap { LOBBY, TEATER, CARI_OBAT, TERKUNCI, ACT0_SELESAI, ACT1_MULAI, ACT1_STUDIO, ACT1_MEMORI1, ACT1_KEJAR, ACT1_STUDIO3 }
var tahap: int = Tahap.LOBBY
var flag := {}

func reset() -> void:
	tahap = Tahap.LOBBY
	flag = {}

func set_flag(nama: String, nilai = true) -> void:
	flag[nama] = nilai

func ambil_flag(nama: String, default = false):
	return flag.get(nama, default)
