extends TextureRect

@export var sheet: Texture2D   # seret Sanity_Bar_.png di Inspector

# Region tiap kondisi, indeks = jumlah kotak (0 sampai 5)
const REGION := [
	Rect2(645, 803, 445, 115),  # 0 kotak
	Rect2(645, 645, 445, 115),  # 1
	Rect2(645, 475, 445, 115),  # 2
	Rect2(645, 313, 445, 115),  # 3
	Rect2(645, 152, 445, 115),  # 4
	Rect2(645, 10, 445, 115),   # 5
]

var atlas: Array[AtlasTexture] = []


func _ready() -> void:
	for r in REGION:
		var a := AtlasTexture.new()
		a.atlas = sheet
		a.region = r
		atlas.append(a)
	SanityManager.sanity_berubah.connect(func(_n): _perbarui())
	_perbarui()


func _perbarui() -> void:
	texture = atlas[clampi(SanityManager.jumlah_kotak(), 0, 5)]
