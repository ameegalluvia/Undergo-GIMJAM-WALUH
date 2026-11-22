extends Sprite2D

@export var layer_acuan: Array[TileMapLayer] = []   # tembok, lantai, tembok tambahan
@export var lebar_kabut := 100                  # seberapa jauh kabut masuk dari tepi (piksel)
@export var warna_kabut := Color.BLACK
@export var cetak_info := false                     # centang untuk melihat ukuran grid di Output

func _ready() -> void:
	centered = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # supaya gradasi halus
	_buat_kabut()

func _buat_kabut() -> void:
	# 1. Kumpulkan semua sel yang berisi tile, dalam koordinat grid dunia
	var ukuran_sel := Vector2.ZERO
	var sel_dunia: Array[Vector2i] = []
	for layer in layer_acuan:
		if layer == null or layer.tile_set == null or not layer.visible:
			continue
		if ukuran_sel == Vector2.ZERO:
			ukuran_sel = Vector2(layer.tile_set.tile_size)
		for sel in layer.get_used_cells():
			var pos := layer.to_global(layer.map_to_local(sel))
			sel_dunia.append(Vector2i(floori(pos.x / ukuran_sel.x), floori(pos.y / ukuran_sel.y)))

	if sel_dunia.is_empty():
		push_warning("KabutRuangan: isi 'Layer Acuan' dengan TileMapLayer ruangan")
		return

	# 2. Hitung batas dan siapkan grid (dengan jeda di sekelilingnya untuk kabut luar)
	var kecil := sel_dunia[0]
	var besar := sel_dunia[0]
	for s in sel_dunia:
		kecil = Vector2i(mini(kecil.x, s.x), mini(kecil.y, s.y))
		besar = Vector2i(maxi(besar.x, s.x), maxi(besar.y, s.y))

	var radius := maxi(2, roundi(lebar_kabut / ukuran_sel.x))
	var jeda := radius + 2
	var asal := kecil - Vector2i(jeda, jeda)
	var lebar := besar.x - kecil.x + 1 + jeda * 2
	var tinggi := besar.y - kecil.y + 1 + jeda * 2

	if cetak_info:
		print("[Kabut] grid %d x %d sel, radius %d sel, jumlah tile %d" % [lebar, tinggi, radius, sel_dunia.size()])
	if lebar * tinggi > 400000:
		push_warning("KabutRuangan: grid sangat besar (%d x %d). Cek tile nyasar atau layer yang tidak perlu di 'Layer Acuan'." % [lebar, tinggi])

	# 3. Isi grid: 1.0 di tempat ada tile, 0.0 di luar
	var data := PackedFloat32Array()
	data.resize(lebar * tinggi)
	for s in sel_dunia:
		data[(s.y - asal.y) * lebar + (s.x - asal.x)] = 1.0

	# 4. Haluskan dua kali supaya tepinya memudar mulus
	var setengah := maxi(1, roundi(radius / 2.0))
	for i in 2:
		data = _buram(data, lebar, tinggi, setengah)

	# 5. Ubah jadi gambar: gelap di luar dan di tepi tile, bening di dalam ruangan
	var bytes := PackedByteArray()
	bytes.resize(lebar * tinggi * 4)
	for i in lebar * tinggi:
		var alpha := clampf(2.0 * (1.0 - data[i]), 0.0, 1.0) * warna_kabut.a
		bytes[i * 4] = warna_kabut.r8
		bytes[i * 4 + 1] = warna_kabut.g8
		bytes[i * 4 + 2] = warna_kabut.b8
		bytes[i * 4 + 3] = int(alpha * 255.0)
	var gambar := Image.create_from_data(lebar, tinggi, false, Image.FORMAT_RGBA8, bytes)
	texture = ImageTexture.create_from_image(gambar)

	# 6. Satu piksel gambar = satu sel tilemap
	global_position = Vector2(asal) * ukuran_sel
	global_scale = ukuran_sel

# Box blur cepat (jendela bergeser), horizontal lalu vertikal
func _buram(data: PackedFloat32Array, w: int, h: int, r: int) -> PackedFloat32Array:
	var norm := 1.0 / float(2 * r + 1)

	var tmp := PackedFloat32Array()
	tmp.resize(w * h)
	for y in h:
		var dasar := y * w
		var jumlah := 0.0
		for k in range(-r, r + 1):
			jumlah += data[dasar + clampi(k, 0, w - 1)]
		for x in w:
			tmp[dasar + x] = jumlah * norm
			jumlah += data[dasar + clampi(x + r + 1, 0, w - 1)] - data[dasar + clampi(x - r, 0, w - 1)]

	var hasil := PackedFloat32Array()
	hasil.resize(w * h)
	for x in w:
		var jumlah := 0.0
		for k in range(-r, r + 1):
			jumlah += tmp[clampi(k, 0, h - 1) * w + x]
		for y in h:
			hasil[y * w + x] = jumlah * norm
			jumlah += tmp[clampi(y + r + 1, 0, h - 1) * w + x] - tmp[clampi(y - r, 0, h - 1) * w + x]
	return hasil
