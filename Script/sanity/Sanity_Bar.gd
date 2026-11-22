extends HBoxContainer

@export var tekstur_penuh: Texture2D
@export var tekstur_kosong: Texture2D   # boleh kosong
@export var warna_kosong := Color(0.2, 0.2, 0.2, 0.5)



func _ready() -> void:
	SanityManager.sanity_berubah.connect(func(_n): _perbarui())
	_perbarui()


func _perbarui() -> void:
	var terisi: int = SanityManager.jumlah_kotak()
	for i in get_child_count():
		var kotak := get_child(i) as TextureRect
		if i < terisi:
			kotak.texture = tekstur_penuh
			kotak.modulate = Color.WHITE
		elif tekstur_kosong:
			kotak.texture = tekstur_kosong
			kotak.modulate = Color.WHITE
		else:
			kotak.texture = tekstur_penuh
			kotak.modulate = warna_kosong
