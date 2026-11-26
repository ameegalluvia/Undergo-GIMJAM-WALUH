extends Control

const SCENE_MAIN_MENU := "res://Scene/sistem/main_menu.tscn"

@export var halaman: Array[HalamanCredit] = []

@export var musik: AudioStream
@export var ukuran_judul := 32
@export var ukuran_isi := 20
@export var awal_hening := 1.0
@export var durasi_fade := 1.2
@export var durasi_fade_cepat := 0.3            # fade out saat halaman dilewati
@export var tahan_minimum := 2.5
@export var tahan_per_baris := 0.8
@export var jeda_antar_halaman := 0.6
@export var bisa_lewati_halaman := true         # Enter / Space / klik
@export var bisa_lewati_semua := true           # Esc

@onready var konten: VBoxContainer = $Tengah/Konten
@onready var judul: Label = $Tengah/Konten/Judul
@onready var isi: Label = $Tengah/Konten/Isi

var _selesai := false
var _lewati := false    # true = pemain minta lewati halaman ini


func _ready() -> void:
	SanityManager.nonaktifkan()
	Inventory.reset()
	InventoryUI.bersihkan_pesan()

	judul.add_theme_font_size_override("font_size", ukuran_judul)
	isi.add_theme_font_size_override("font_size", ukuran_isi)
	konten.modulate.a = 0.0

	if musik != null:
		AudioManager.play_music(musik, 1.0)

	_putar()


func _putar() -> void:
	await _tunggu(awal_hening, false)
	for h in halaman:
		if _selesai:
			return
		if h == null:
			continue
		_tampilkan_halaman(h)
		_lewati = false

		var jumlah_baris: int = h.isi.split("\n").size()
		var tahan := tahan_minimum + tahan_per_baris * maxi(jumlah_baris - 1, 0)

		# Fade in, lalu tahan. Keduanya bisa diinterupsi oleh _lewati.
		var dilewati := await _fade(1.0, durasi_fade, true)
		if not dilewati and not _selesai:
			dilewati = await _tunggu(tahan, true)
		if _selesai:
			return

		# Fade out: cepat kalau dilewati, normal kalau tidak. Tidak bisa diinterupsi.
		await _fade(0.0, durasi_fade_cepat if dilewati else durasi_fade, false)
		if _selesai:
			return

		await _tunggu(jeda_antar_halaman, false)
		_lewati = false   # buang klik yang masuk saat layar kosong

	if _selesai:
		return
	await _tunggu(1.0, false)
	_kembali_ke_menu()


func _tampilkan_halaman(h: HalamanCredit) -> void:
	judul.text = h.judul
	judul.visible = h.judul != ""
	isi.text = h.isi
	isi.visible = h.isi != ""


# Mengembalikan true kalau diinterupsi oleh _lewati
func _fade(target: float, durasi: float, bisa_diinterupsi: bool) -> bool:
	var awal := konten.modulate.a
	var t := 0.0
	while t < durasi:
		if _selesai:
			return false
		if bisa_diinterupsi and _lewati:
			_lewati = false
			return true
		await get_tree().process_frame
		t += get_process_delta_time()
		konten.modulate.a = lerpf(awal, target, clampf(t / durasi, 0.0, 1.0))
	konten.modulate.a = target
	return false


# Mengembalikan true kalau diinterupsi oleh _lewati
func _tunggu(detik: float, bisa_diinterupsi: bool) -> bool:
	var sisa := detik
	while sisa > 0.0:
		if _selesai:
			return false
		if bisa_diinterupsi and _lewati:
			_lewati = false
			return true
		await get_tree().process_frame
		sisa -= get_process_delta_time()
	return false


func _input(event: InputEvent) -> void:
	if _selesai:
		return

	# Esc: lewati semua
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if bisa_lewati_semua:
			_kembali_ke_menu()
		return

	# Enter, Space, atau klik kiri: lewati halaman ini
	var klik: bool = event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT
	if klik or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if bisa_lewati_halaman:
			_lewati = true


func _kembali_ke_menu() -> void:
	if _selesai:
		return
	_selesai = true
	AudioManager.fade_out_music(0.5)
	await Transisi.fade_keluar_dan_jalankan(func() -> void:
		get_tree().change_scene_to_file(SCENE_MAIN_MENU)
	, true)
