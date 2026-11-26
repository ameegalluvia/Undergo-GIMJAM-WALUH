extends Control

const SCENE_MAIN_MENU := "res://Scene/sistem/main_menu.tscn"

@export var halaman: Array[HalamanCredit] = []   # isi lewat Inspector

@export var musik: AudioStream                  # opsional, lagu credit
@export var ukuran_judul := 32
@export var ukuran_isi := 20
@export var awal_hening := 1.0
@export var durasi_fade := 1.2
@export var tahan_minimum := 2.5
@export var tahan_per_baris := 0.8
@export var jeda_antar_halaman := 0.6

@onready var konten: VBoxContainer = $Tengah/Konten
@onready var judul: Label = $Tengah/Konten/Judul
@onready var isi: Label = $Tengah/Konten/Isi

var _selesai := false

func _ready() -> void:
	SanityManager.nonaktifkan()
	Inventory.reset()
	InventoryUI.bersihkan_pesan()
	AudioManager.play_music(preload("res://assets/audio/tambahan/ending.wav"))

	judul.add_theme_font_size_override("font_size", ukuran_judul)
	isi.add_theme_font_size_override("font_size", ukuran_isi)
	konten.modulate.a = 0.0

	if musik != null:
		AudioManager.play_music(musik, 1.0)

	_putar()


func _putar() -> void:
	await _tunggu(awal_hening)
	for h in halaman:
		if _selesai:
			return
		if h == null:
			continue
		_tampilkan_halaman(h)
		var jumlah_baris: int = h.isi.split("\n").size()
		var tahan := tahan_minimum + tahan_per_baris * maxi(jumlah_baris - 1, 0)

		await _fade(1.0)
		if _selesai:
			return
		await _tunggu(tahan)
		if _selesai:
			return
		await _fade(0.0)
		if _selesai:
			return
		await _tunggu(jeda_antar_halaman)

	if _selesai:
		return
	await _tunggu(1.0)
	_kembali_ke_menu()


func _tampilkan_halaman(h: HalamanCredit) -> void:
	judul.text = h.judul
	judul.visible = h.judul != ""
	isi.text = h.isi
	isi.visible = h.isi != ""


func _fade(target: float) -> void:
	var tw := create_tween()
	tw.tween_property(konten, "modulate:a", target, durasi_fade)
	await tw.finished


func _tunggu(detik: float) -> void:
	var tw := create_tween()
	tw.tween_interval(detik)
	await tw.finished


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_kembali_ke_menu()


func _kembali_ke_menu() -> void:
	if _selesai:
		return
	_selesai = true
	AudioManager.fade_out_music(0.5)
	await Transisi.fade_keluar_dan_jalankan(func() -> void:
		get_tree().change_scene_to_file(SCENE_MAIN_MENU)
	, true)
