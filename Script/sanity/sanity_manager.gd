extends Node

signal sanity_berubah(nilai: float)
signal state_berubah(baru: int, lama: int)
signal aktif_berubah(status: bool)
signal sanity_habis

enum State { HIJAU, KUNING, MERAH, MATI }

const MAKS := 100.0
const DRAIN_PER_MENIT := 10.0
const NILAI_PER_KOTAK := 20.0

var nilai := MAKS
var state := State.HIJAU
var aktif := false   # false = Act 0, sistem mati total
var dijeda := false

func jeda_drain() -> void:
	dijeda = true

func lanjut_drain() -> void:
	dijeda = false	

func _process(delta: float) -> void:
	if aktif and not dijeda and not get_tree().paused:
		ubah(-DRAIN_PER_MENIT / 60.0 * delta)


func aktifkan() -> void:
	aktif = true
	aktif_berubah.emit(true)

func nonaktifkan() -> void:
	aktif = false
	aktif_berubah.emit(false)

func kurangi(jumlah: float) -> void:
	ubah(-jumlah)

func tambah(jumlah: float) -> void:
	ubah(jumlah)

func reset() -> void:
	set_nilai(MAKS)

func set_nilai(baru: float) -> void:
	nilai = clampf(baru, 0.0, MAKS)
	state = _hitung_state()
	sanity_berubah.emit(nilai)


func ubah(jumlah: float) -> void:
	if not aktif or state == State.MATI:
		return
	var lama := nilai
	nilai = clampf(nilai + jumlah, 0.0, MAKS)
	if is_equal_approx(lama, nilai):
		return
	sanity_berubah.emit(nilai)

	var baru := _hitung_state()
	if baru != state:
		var state_lama := state
		state = baru
		state_berubah.emit(baru, state_lama)
		if baru == State.MATI:
			sanity_habis.emit()


func jumlah_kotak() -> int:
	return ceili(nilai / NILAI_PER_KOTAK)


func _hitung_state() -> int:
	if nilai <= 0.0:
		return State.MATI
	if nilai < 20.0:
		return State.MERAH
	if nilai <= 60.0:
		return State.KUNING
	return State.HIJAU

func pakai_obat(item: DataItem) -> bool:
	if item == null or item.heal_sanity <= 0.0:
		return false
	if not aktif or nilai >= MAKS:
		return false
	tambah(item.heal_sanity)
	return true
