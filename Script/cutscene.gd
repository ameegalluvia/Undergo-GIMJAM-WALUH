extends Control

@export var dialog: Array[DialogLine] = []
@export_file("*.tscn") var scene_berikutnya: String = ""
@export var kecepatan_teks: float = 30.0  

@onready var gambar: TextureRect = $Gambar
@onready var nama: Label = $MessageBox/Margin/VBox/Nama
@onready var teks: Label = $MessageBox/Margin/VBox/Teks

var index := 0
var tween: Tween


func _ready() -> void:
	if dialog.is_empty():
		push_warning("Dialog kosong, isi di Inspector node Cutscene.")
		return
	tampilkan()


func tampilkan() -> void:
	var data: DialogLine = dialog[index]

	if data.gambar:
		gambar.texture = data.gambar

	nama.text = data.nama
	nama.visible = not data.nama.is_empty()

	teks.text = data.teks
	teks.visible_ratio = 0.0

	var durasi := data.teks.length() / kecepatan_teks
	tween = create_tween()
	tween.tween_property(teks, "visible_ratio", 1.0, durasi)


func sedang_mengetik() -> bool:
	return tween != null and tween.is_running()


func _input(event: InputEvent) -> void:
	var klik: bool = event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT

	if klik or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		lanjut()


func lanjut() -> void:
	if dialog.is_empty():
		return

	if sedang_mengetik():
		tween.kill()
		teks.visible_ratio = 1.0
		return

	index += 1
	if index >= dialog.size():
		selesai()
	else:
		tampilkan()


func selesai() -> void:
	if scene_berikutnya.is_empty():
		print("Cutscene selesai")
	else:
		get_tree().change_scene_to_file(scene_berikutnya)
