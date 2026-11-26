extends Node

signal sanity_berubah(nilai: float)
signal state_berubah(baru: int, lama: int)
signal aktif_berubah(status: bool)
signal sanity_habis


enum State { HIJAU, KUNING, MERAH, MATI }

const MAKS := 100.0
const TURUN_SANITY := 10.0   # sanity yang hilang...
const TIAP_MENIT := 3.0      # ...setiap sekian menit
const NILAI_PER_KOTAK := 20.0

var nilai := MAKS
var state := State.HIJAU
var johan_glitch := false   # status sprite glitch, bertahan antar scene
var sudah_mati := false
var aktif := false   # false = Act 0, sistem mati total
var dijeda := false

func jeda_drain() -> void:
	dijeda = true

func lanjut_drain() -> void:
	dijeda = false	

func _process(delta: float) -> void:
	if aktif and not dijeda and not get_tree().paused:
		ubah(-TURUN_SANITY / (TIAP_MENIT * 60.0) * delta)


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

# Dipakai load/respawn: memulihkan nilai dan membuka status mati
func set_nilai(baru: float) -> void:
	sudah_mati = false
	_terapkan(baru, true)


func ubah(jumlah: float) -> void:
	if not aktif or sudah_mati:
		return
	_terapkan(nilai + jumlah, false)


func _terapkan(baru: float, tanpa_mati: bool) -> void:
	var lama := nilai
	nilai = clampf(baru, 0.0, MAKS)
	if is_equal_approx(lama, nilai) and not tanpa_mati:
		return
	sanity_berubah.emit(nilai)

	var s := _hitung_state()
	if s != state:
		var state_lama := state
		state = s
		state_berubah.emit(s, state_lama)

	if nilai <= 0.0 and not sudah_mati and not tanpa_mati:
		sudah_mati = true
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
