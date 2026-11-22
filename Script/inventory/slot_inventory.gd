class_name SlotInventory
extends Button

const BORDER_BIASA := Color(0.25, 0.25, 0.25)
const BORDER_AKTIF := Color(0.2, 0.9, 0.3)   # hijau, ganti sesukamu

var _ikon: TextureRect
var _label: Label
var _terpilih := false

func _init() -> void:
	custom_minimum_size = Vector2(200, 72)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_NONE

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for sisi in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + sisi, 8)
	add_child(margin)

	var baris := HBoxContainer.new()
	baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baris.add_theme_constant_override("separation", 12)
	margin.add_child(baris)

	_ikon = TextureRect.new()
	_ikon.custom_minimum_size = Vector2(56, 56)
	_ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ikon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # biar pixel art tajam
	_ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baris.add_child(_ikon)

	_label = Label.new()
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baris.add_child(_label)

	_segarkan_gaya()

func atur_item(item: DataItem) -> void:
	if item:
		_ikon.texture = item.ikon
		_label.text = item.nama_tampil
		disabled = false
	else:
		_ikon.texture = null
		_label.text = "-"
		disabled = true

func atur_terpilih(nilai: bool) -> void:
	_terpilih = nilai
	_segarkan_gaya()

func _segarkan_gaya() -> void:
	if _terpilih:
		# slot terpilih memakai tampilan "pressed" dari Theme
		add_theme_stylebox_override("normal", get_theme_stylebox("pressed"))
	else:
		remove_theme_stylebox_override("normal")

func _buat_kotak(warna_border: Color) -> StyleBoxFlat:
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	gaya.border_color = warna_border
	gaya.set_border_width_all(3)
	gaya.set_corner_radius_all(4)
	return gaya
