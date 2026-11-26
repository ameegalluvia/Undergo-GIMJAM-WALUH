extends Control

@export var kecepatan_teks: float = 30.0
@export var durasi_transisi: float = 0.6

@onready var gambar: TextureRect = $Gambar
@onready var gambar_baru: TextureRect = $GambarBaru
@onready var nama: Label = $MessageBox/Margin/VBox/Nama
@onready var teks: Label = $MessageBox/Margin/VBox/Teks

var data: CutsceneData
var dialog: Array[DialogLine] = []
var index := 0
var tween: Tween
var tween_gambar: Tween


func _ready() -> void:
	gambar_baru.modulate.a = 0.0
	data = CutsceneManager.data_aktif
	if data == null or data.dialog.is_empty():
		push_warning("Tidak ada data cutscene. Mulai lewat CutsceneManager.mainkan().")
		return
	dialog = data.dialog
	tampilkan()


func tampilkan() -> void:
	var baris: DialogLine = dialog[index]
	
	if baris.stop_backsound:
		AudioManager.stop_backsound()
	elif baris.backsound:
		AudioManager.play_backsound(baris.backsound, baris.volume_backsound_db)
	# kosong: backsound sebelumnya tetap lanjut

	if baris.gambar:
		ganti_gambar(baris.gambar, baris.pakai_transisi)

	nama.text = baris.nama
	nama.visible = not baris.nama.is_empty()

	teks.text = baris.teks
	teks.visible_ratio = 0.0

	var durasi := baris.teks.length() / kecepatan_teks
	tween = create_tween()
	tween.tween_property(teks, "visible_ratio", 1.0, durasi)
	tween.finished.connect(SuaraTeks.berhenti)
	SuaraTeks.mulai(durasi, baris.suara_teks_khusus)
	if baris.suara_tambahan:
		AudioManager.play_sfx_volume(baris.suara_tambahan, baris.volume_tambahan_db)


func ganti_gambar(tekstur: Texture2D, transisi: bool) -> void:
	if tween_gambar and tween_gambar.is_running():
		tween_gambar.kill()
		gambar.texture = gambar_baru.texture
		gambar_baru.modulate.a = 0.0

	if not transisi or gambar.texture == null:
		gambar.texture = tekstur
		gambar_baru.modulate.a = 0.0
		return

	gambar_baru.texture = tekstur
	gambar_baru.modulate.a = 0.0
	tween_gambar = create_tween()
	tween_gambar.tween_property(gambar_baru, "modulate:a", 1.0, durasi_transisi)
	tween_gambar.tween_callback(func():
		gambar.texture = tekstur
		gambar_baru.modulate.a = 0.0
	)


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
	AudioManager.stop_backsound(0.8)
	if data.scene_berikutnya.is_empty():
		print("Cutscene selesai")
	else:
		get_tree().change_scene_to_file(data.scene_berikutnya)
