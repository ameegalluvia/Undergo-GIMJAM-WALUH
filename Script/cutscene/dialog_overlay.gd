extends CanvasLayer

signal aksi_dipicu(nama: String)
signal selesai_dialog

@export var kecepatan_teks: float = 30.0

@onready var kotak: Control = $MessageBox
@onready var nama: Label = $MessageBox/Nama
@onready var teks: Label = $MessageBox/Teks
@onready var potret: TextureRect = $MessageBox/Potret

var dialog: Array[DialogLine] = []
var index := 0
var tween: Tween
var aktif := false
var menunggu_aksi := false


func _ready() -> void:
	# ALWAYS supaya _process tetap jalan saat pause dan bisa menyembunyikan dialog.
	# Input dan ketikan teks dijaga manual di bawah.
	process_mode = Node.PROCESS_MODE_ALWAYS
	kotak.visible = false
	aktif = false
	add_to_group("dialog_overlay")


func _process(_delta: float) -> void:
	# Sembunyikan seluruh layer dialog saat pause menu atau inventory terbuka
	visible = not _terblokir()


func _terblokir() -> bool:
	return get_tree().paused or Inventory.ui_terbuka


func mulai(data: CutsceneData) -> void:
	if data == null or data.dialog.is_empty():
		return
	dialog = data.dialog
	index = 0
	aktif = true
	kotak.visible = true
	tampilkan()


func tampilkan() -> void:
	var baris: DialogLine = dialog[index]

	nama.text = baris.nama
	nama.visible = not baris.nama.is_empty()

	potret.texture = baris.potret
	potret.visible = baris.potret != null

	teks.text = baris.teks
	teks.visible_ratio = 0.0
	tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)   # ketikan berhenti saat pause
	tween.tween_property(teks, "visible_ratio", 1.0, baris.teks.length() / kecepatan_teks)

	if not baris.aksi.is_empty():
		menunggu_aksi = baris.tunggu_aksi
		aksi_dipicu.emit(baris.aksi)


# Dipanggil scene gameplay saat aksi yang ditunggu selesai
func aksi_selesai() -> void:
	menunggu_aksi = false


func sedang_mengetik() -> bool:
	return tween != null and tween.is_running()


func _input(event: InputEvent) -> void:
	if not aktif or _terblokir():
		return
	var klik: bool = event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT
	if klik or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		lanjut()


func lanjut() -> void:
	if sedang_mengetik():
		tween.kill()
		teks.visible_ratio = 1.0
		return
	if menunggu_aksi:
		return

	index += 1
	if index >= dialog.size():
		aktif = false
		kotak.visible = false
		selesai_dialog.emit()
	else:
		tampilkan()
