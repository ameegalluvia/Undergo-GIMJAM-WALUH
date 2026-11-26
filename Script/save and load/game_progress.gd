extends Node

enum Tahap { LOBBY, TEATER, CARI_OBAT, TERKUNCI, ACT0_SELESAI, ACT1_MULAI, ACT1_STUDIO, ACT1_MEMORI1, ACT1_KEJAR, ACT1_STUDIO3, ACT1_BONEKA, ACT1_MEMORI2, ACT1_KONTROL,ACT1_KONTROL_TERKUNCI, ACT1_PALU, ACT1_GUDANG, ACT1_TEMBOK, ACT1_KONTROL_ROOM, ACT1_SAKLAR, ACT1_KASET, ACT1_ENDING }
var tahap: int = Tahap.LOBBY
var flag := {}

func reset() -> void:
	tahap = Tahap.LOBBY
	flag = {}

func set_flag(nama: String, nilai = true) -> void:
	flag[nama] = nilai

func ambil_flag(nama: String, default = false):
	return flag.get(nama, default)
