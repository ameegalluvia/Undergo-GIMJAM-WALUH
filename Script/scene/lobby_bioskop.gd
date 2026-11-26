extends AdeganBase

@onready var npc1 = $Npc1
@onready var npc2 = $Npc2
@onready var titik_masuk = $TitikMasuk
@onready var titik_tengah = $TitikTengah
@onready var titik_maju = $TitikKonter
@onready var titik_keluar = $TitikKeluar
@onready var area_konter: Area2D = $AreaKonter


func _ready() -> void:
	super()
	area_konter.body_entered.connect(_on_area_konter)
	area_konter.monitoring = false

	# Sudah lewat cutscene masuk (kembali ke lobby / Continue)
	if GameProgress.ambil_flag("cs_lobby_masuk"):
		npc1.visible = false
		npc2.visible = false
		if not GameProgress.ambil_flag("cs_lobby_konter"):
			area_konter.monitoring = true
		return

	# Cutscene 1: Johan masuk, jalan ke tengah, NPC bicara
	_kunci_pemain(true)
	johan.global_position = titik_masuk.global_position
	await get_tree().create_timer(0.5).timeout
	await _jalan(johan, titik_tengah.global_position)
	johan.last_dir = "up"
	johan.main_diam()
	mainkan_sekali("cs_lobby_masuk", preload("res://Data/Cutscene/adeganbioskop1.tres"))


func selesai_cutscene() -> void:
	# Setelah cutscene 1: pemain menuntun Johan ke konter
	if GameProgress.ambil_flag("cs_lobby_masuk") and not GameProgress.ambil_flag("cs_lobby_konter"):
		area_konter.set_deferred("monitoring", true)
		SaveManager.simpan_scene(scene_file_path)
		return
	# Setelah cutscene 2: gameplay bebas
	if GameProgress.ambil_flag("cs_lobby_konter"):
		SaveManager.simpan_scene(scene_file_path)


func _on_area_konter(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if GameProgress.ambil_flag("cs_lobby_konter"):
		return
	area_konter.set_deferred("monitoring", false)
	_kunci_pemain(true)
	mainkan_sekali("cs_lobby_konter", preload("res://Data/Cutscene/adeganbioskop2.tres"))
	
func _jalan(node: Node2D, titik: Vector2, kecepatan: float = KECEPATAN_JALAN) -> void:
	var arah := titik - node.global_position
	var durasi := arah.length() / kecepatan

	if node.has_method("main_jalan"):
		node.main_jalan(arah)   # Johan
	else:
		_animasi_npc(node, arah)

	var tw := create_tween()
	tw.tween_property(node, "global_position", titik, durasi)
	await tw.finished

	if node.has_method("main_diam"):
		node.main_diam()
	else:
		_diam_npc(node)


func _sprite_npc(node: Node) -> AnimatedSprite2D:
	if node is AnimatedSprite2D:
		return node
	return node.get_node_or_null("AnimatedSprite2D")


func _animasi_npc(node: Node2D, arah: Vector2) -> void:
	var sprite := _sprite_npc(node)
	if sprite == null:
		return

	var sisi := "right" if arah.x > 0 else "left"
	if abs(arah.y) > abs(arah.x):
		sisi = "down" if arah.y > 0 else "up"

	# Coba beberapa nama, pakai yang pertama ada
	for nama in ["walk_" + sisi, "walk", "jalan"]:
		if sprite.sprite_frames.has_animation(nama):
			sprite.play(nama)
			return

	push_warning("NPC %s tidak punya animasi jalan. Animasi yang ada: %s" % [node.name, sprite.sprite_frames.get_animation_names()])


func _diam_npc(node: Node2D) -> void:
	var sprite := _sprite_npc(node)
	if sprite == null:
		return
	for nama in ["idle", "diam"]:
		if sprite.sprite_frames.has_animation(nama):
			sprite.play(nama)
			return


func aksi_khusus(nama: String) -> void:
	match nama:
		"npc_keluar":
			_jalan_hilang(npc1, titik_keluar.global_position)
			await _jalan_hilang(npc2, titik_keluar.global_position + Vector2(60, 0))
		"ambil_tiket":
			var tiket: DataItem = preload("res://Data/Items/tiket_bioskop.tres")
			Inventory.tambah_item(tiket)
		"auto_maju":
			await _jalan(johan, titik_maju.global_position)
	overlay.aksi_selesai()


func _jalan_hilang(node: Node2D, titik: Vector2) -> void:
	await _jalan(node, titik)
	node.visible = false
