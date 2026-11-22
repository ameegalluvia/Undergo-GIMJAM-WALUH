extends Node

signal sanity_berubah(nilai: float)
signal aktif_berubah(status: bool)

const MAKS := 100.0
const DRAIN_PER_MENIT := 10.0
const NILAI_PER_KOTAK := 20.0

var nilai := MAKS
var aktif := false  


func _process(delta: float) -> void:
	if aktif:
		ubah(-DRAIN_PER_MENIT / 60.0 * delta)


func aktifkan() -> void:
	aktif = true
	aktif_berubah.emit(true)


func nonaktifkan() -> void:
	aktif = false
	aktif_berubah.emit(false)


func ubah(jumlah: float) -> void:
	if not aktif:
		return
	nilai = clampf(nilai + jumlah, 0.0, MAKS)
	sanity_berubah.emit(nilai)


func kurangi(jumlah: float) -> void:
	ubah(-jumlah)


func tambah(jumlah: float) -> void:
	ubah(jumlah)


func reset() -> void:
	nilai = MAKS
	sanity_berubah.emit(nilai)


func jumlah_kotak() -> int:
	return ceili(nilai / NILAI_PER_KOTAK)
