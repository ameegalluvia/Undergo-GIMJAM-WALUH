extends HBoxContainer

@export var tekstur_penuh: Texture2D
@export var tekstur_kosong: Texture2D


func _ready() -> void:
	SanityManager.sanity_berubah.connect(func(_n, _m): _perbarui())
	_perbarui()


func _perbarui() -> void:
	var terisi := SanityManager.jumlah_kotak()
	for i in get_child_count():
		var kotak := get_child(i) as TextureRect
		kotak.texture = tekstur_penuh if i < terisi else tekstur_kosong
