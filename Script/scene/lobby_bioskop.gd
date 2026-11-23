extends Node2D

const KECEPATAN_JALAN := 40.0   # samakan dengan speed Player

@onready var overlay = $DialogOverlay
@onready var johan = $Player
@onready var npc1 = $Npc1
@onready var npc2 = $Npc2
@onready var titik_masuk = $TitikMasuk
@onready var titik_tengah = $TitikTengah
@onready var titik_maju = $TitikKonter
@onready var titik_keluar = $TitikKeluar
@onready var area_konter = $AreaKonter
var cutscene_selesai := false


func _ready() -> void:
	overlay.aksi_dipicu.connect(_on_aksi)
	overlay.selesai_dialog.connect(_on_selesai_dialog)
	_kunci_pemain(true)

	# Aksi awal: Johan masuk dari pintu dan jalan sendiri ke tengah
	johan.global_position = titik_masuk.global_position
	await get_tree().create_timer(0.5).timeout
	await _jalan(johan, titik_tengah.global_position)

	johan.last_dir = "up"   # menghadap list film, sesuaikan arahnya
	johan.main_diam()

	# Dialog dimulai (Johan melihat list film)
	overlay.mulai(preload("res://Data/Cutscene/adeganbioskop1.tres"))


# ---------- Kendali pemain ----------
func _kunci_pemain(kunci: bool) -> void:
	johan.velocity = Vector2.ZERO
	johan.set_physics_process(not kunci)


# ---------- Gerak otomatis ----------
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


func _jalan_lalu_hilang(node: Node2D, titik: Vector2) -> void:
	await _jalan(node, titik)
	node.visible = false


# ---------- Pemain menuntun Johan ----------
func _tuntun_ke(area: Area2D) -> void:
	overlay.get_node("MessageBox").visible = false
	_kunci_pemain(false)
	while true:
		var body = await area.body_entered
		if body.is_in_group("player"):
			break
	_kunci_pemain(true)
	overlay.get_node("MessageBox").visible = true


# ---------- Aksi dari dialog ----------
func _on_aksi(nama: String) -> void:
	match nama:
		"npc_keluar":
			_jalan_lalu_hilang(npc1, titik_keluar.global_position)
			await _jalan_lalu_hilang(npc2, titik_keluar.global_position + Vector2(60, 0))
			overlay.aksi_selesai()

		"kontrol_ke_konter":
			await _tuntun_ke(area_konter)
			overlay.aksi_selesai()

		"auto_maju":
			await _jalan(johan, titik_maju.global_position)
			overlay.aksi_selesai()
			
		"ambil_tiket":
			var tiket: DataItem = preload("res://Data/Items/tiket_bioskop.tres")   # sesuaikan path
			if Inventory.tambah_item(tiket):
				InventoryUI.umumkan_item_diambil(tiket)
			else:
				InventoryUI.tampilkan_pesan("Inventory penuh!", 2.0)
			overlay.aksi_selesai()


# ---------- Setelah cutscene ----------
func _on_selesai_dialog() -> void:
	cutscene_selesai = true
	_kunci_pemain(false)   # gameplay bebas, tanpa dialog
