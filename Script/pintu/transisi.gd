extends CanvasLayer

const DURASI_FADE := 0.6

var sedang_transisi := false
var _layar: ColorRect

func _ready() -> void:
	layer = 80   # di atas HUD dan Inventory (50), di bawah pause menu (100)
	process_mode = Node.PROCESS_MODE_ALWAYS

	_layar = ColorRect.new()
	_layar.color = Color.BLACK
	add_child(_layar)
	_layar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layar.modulate.a = 0.0

# Fade ke hitam, pindah scene, taruh pemain di titik tujuan, lalu fade kembali
func pindah_scene(path: String, id_titik: StringName = &"") -> void:
	if sedang_transisi:
		return
	sedang_transisi = true
	_layar.mouse_filter = Control.MOUSE_FILTER_STOP   # blokir klik selama transisi

	await _fade(1.0)

	var hasil := get_tree().change_scene_to_file(path)
	if hasil != OK:
		push_error("Transisi: gagal memuat scene " + path)
	else:
		await get_tree().process_frame
		await get_tree().process_frame   # tunggu scene baru selesai _ready()
		_tempatkan_pemain(id_titik)

	await _fade(0.0)
	_layar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sedang_transisi = false

func _fade(target: float) -> void:
	var tween := create_tween()
	tween.tween_property(_layar, "modulate:a", target, DURASI_FADE)
	await tween.finished

func _tempatkan_pemain(id_titik: StringName) -> void:
	if id_titik == &"":
		return   # tidak ada tujuan khusus, pemain tetap di posisi awal scene
	var pemain := get_tree().get_first_node_in_group("player") as Node2D
	if pemain == null:
		return
	for titik in get_tree().get_nodes_in_group("titik_spawn"):
		if titik.get("id_titik") == id_titik:
			pemain.global_position = titik.global_position
			# supaya kamera tidak meluncur dari posisi lama
			var kamera := pemain.get_node_or_null("Camera2D") as Camera2D
			if kamera:
				kamera.reset_smoothing()
			return
	push_warning("Transisi: titik spawn '%s' tidak ditemukan di scene tujuan" % id_titik)

func fade_keluar_dan_jalankan(aksi: Callable, fade_kembali_otomatis := true) -> void:
	if sedang_transisi:
		return
	sedang_transisi = true
	_layar.mouse_filter = Control.MOUSE_FILTER_STOP

	await _fade(1.0)
	if aksi.is_valid():
		aksi.call()

	if fade_kembali_otomatis:
		await get_tree().process_frame
		await get_tree().process_frame
		await _fade(0.0)
		_layar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sedang_transisi = false
