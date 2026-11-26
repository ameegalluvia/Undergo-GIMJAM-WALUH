extends Node


const SUARA_HOVER: AudioStream = preload("res://assets/audio/sfx/HoverButton.wav")
const SUARA_KLIK: AudioStream = preload("res://assets/audio/sfx/ClickButton.wav")

const VOLUME_HOVER_DB := -10.0
const VOLUME_KLIK_DB := -4.0
const META_TERPASANG := &"ui_suara_terpasang"
const GRUP_TANPA_SUARA := &"tanpa_suara"   # masukkan tombol ke grup ini kalau tidak mau bersuara


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # tetap jalan saat pause menu terbuka
	get_tree().node_added.connect(_pasang)
	_pasang_rekursif(get_tree().root)


func _pasang_rekursif(node: Node) -> void:
	_pasang(node)
	for anak in node.get_children():
		_pasang_rekursif(anak)


func _pasang(node: Node) -> void:
	if not (node is BaseButton):
		return
	if node.has_meta(META_TERPASANG):
		return
	node.set_meta(META_TERPASANG, true)

	var tombol := node as BaseButton
	tombol.mouse_entered.connect(_on_hover.bind(tombol))
	tombol.focus_entered.connect(_on_hover.bind(tombol))   # navigasi keyboard atau gamepad
	tombol.pressed.connect(_on_klik.bind(tombol))


func _boleh_bunyi(tombol: BaseButton) -> bool:
	return is_instance_valid(tombol) \
			and not tombol.disabled \
			and not tombol.is_in_group(GRUP_TANPA_SUARA)


func _on_hover(tombol: BaseButton) -> void:
	if _boleh_bunyi(tombol):
		AudioManager.play_sfx_volume(SUARA_HOVER, VOLUME_HOVER_DB)


func _on_klik(tombol: BaseButton) -> void:
	if _boleh_bunyi(tombol):
		AudioManager.play_sfx_volume(SUARA_KLIK, VOLUME_KLIK_DB)
