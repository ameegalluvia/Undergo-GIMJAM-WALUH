extends Node2D
# Taruh sebagai anak dari objek puzzle (Area2D yang pakai objek_puzzle.gd).
# Otomatis aktif saat puzzle terbuka. Tidak aktif saat scene hanya memulihkan keadaan.

@export var puzzle: Area2D                        # kosong = pakai parent
@export var suara: AudioStream                    # SFX kaca pecah / tembok hancur
@export var warna := Color(0.75, 0.9, 1.0)        # biru muda = kaca, abu/coklat = tembok
@export var jumlah := 24
@export var kecepatan_min := 40.0
@export var kecepatan_max := 120.0
@export var gravitasi := 220.0
@export var durasi := 0.8
@export var ukuran_min := 1.5
@export var ukuran_max := 3.5


func _ready() -> void:
	if puzzle == null:
		puzzle = get_parent() as Area2D
	if puzzle == null:
		push_warning("EfekHancur '%s' tidak menemukan parent" % name)
		return
	if puzzle.has_signal("item_diambil"):          # tempat_item.gd
		puzzle.item_diambil.connect(_on_item_diambil)
	elif puzzle.has_signal("terbuka"):             # objek_puzzle.gd
		puzzle.terbuka.connect(_on_terbuka)
	else:
		push_warning("EfekHancur '%s': parent tidak punya signal yang cocok" % name)


func _on_item_diambil(_item: DataItem) -> void:
	_picu()


func _on_terbuka(dengan_efek: bool) -> void:
	if dengan_efek:
		_picu()


func _picu() -> void:
	if suara != null:
		AudioManager.play_sfx(suara)
	_ledakan()


func _ledakan() -> void:
	var p := CPUParticles2D.new()
	p.z_index = 10
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.one_shot = true
	p.emitting = false
	p.amount = jumlah
	p.lifetime = durasi
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = kecepatan_min
	p.initial_velocity_max = kecepatan_max
	p.gravity = Vector2(0, gravitasi)
	p.scale_amount_min = ukuran_min
	p.scale_amount_max = ukuran_max
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0

	var g := Gradient.new()
	g.set_color(0, warna)
	g.set_color(1, Color(warna.r, warna.g, warna.b, 0.0))   # memudar di akhir
	p.color_ramp = g

	add_child(p)
	p.finished.connect(p.queue_free)
	p.emitting = true
