class_name AdeganBase
extends Node2D

const KECEPATAN_JALAN := 40.0

@onready var overlay = $DialogOverlay
@onready var johan = $Player

var _id_aktif := ""
var fade: ColorRect

func _ready() -> void:
	_buat_fade()
	overlay.aksi_dipicu.connect(_on_aksi)
	overlay.selesai_dialog.connect(_on_selesai)
	GameProgress.set_flag("titik_muncul", "")
	if GameProgress.tahap < GameProgress.Tahap.ACT0_SELESAI:
		SanityManager.nonaktifkan()
	var nama_respawn: String = str(GameProgress.ambil_flag("titik_respawn", ""))
	if GameProgress.ambil_flag("dari_respawn", false) and nama_respawn != "" and has_node(nama_respawn):
		await get_tree().process_frame
		johan.global_position = get_node(nama_respawn).global_position
		GameProgress.set_flag("dari_respawn", false)
	_atur_collision_act0()


func _buat_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100                      # di atas semua UI
	add_child(layer)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)         # mulai transparan
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)


# ---------- Cutscene sekali saja ----------
func mainkan_sekali(id: String, data: CutsceneData) -> bool:
	if GameProgress.ambil_flag(id):
		return false
	_id_aktif = id
	_kunci_pemain(true)
	overlay.mulai(data)
	return true


func _on_selesai() -> void:
	if _id_aktif != "":
		GameProgress.set_flag(_id_aktif)
		_id_aktif = ""
	_kunci_pemain(false)
	selesai_cutscene()


func selesai_cutscene() -> void:   # di-override scene
	pass


# ---------- Pemain dan gerak ----------
func _kunci_pemain(kunci: bool) -> void:
	johan.velocity = Vector2.ZERO
	johan.set_physics_process(not kunci)
	if kunci:
		johan.main_diam()


func _jalan(node: Node2D, titik: Vector2, kecepatan: float = KECEPATAN_JALAN) -> void:
	var arah := titik - node.global_position
	if node.has_method("main_jalan"):
		node.main_jalan(arah)
	var tw := create_tween()
	tw.tween_property(node, "global_position", titik, arah.length() / kecepatan)
	await tw.finished
	if node.has_method("main_diam"):
		node.main_diam()


func _tuntun_ke(area: Area2D) -> void:
	overlay.get_node("MessageBox").visible = false
	_kunci_pemain(false)
	while true:
		var body = await area.body_entered
		if body.is_in_group("player"):
			break
	_kunci_pemain(true)
	overlay.get_node("MessageBox").visible = true


func _fade(alpha: float, durasi := 1.0) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", alpha, durasi)
	await tw.finished


# ---------- Pindah scene ----------
func pindah(path: String, spawn := "", tahap_baru := -1) -> void:
	if tahap_baru >= 0:
		GameProgress.tahap = tahap_baru
	GameProgress.set_flag("titik_muncul", spawn)
	SaveManager.simpan_scene(path)
	get_tree().change_scene_to_file(path)


# ---------- Aksi umum ----------
func _on_aksi(nama: String) -> void:
	match nama:
		"fade_hitam":
			await _fade(1.0)
			overlay.aksi_selesai()
		"fade_terang":
			await _fade(0.0)
			overlay.aksi_selesai()
		"tunggu":
			await get_tree().create_timer(1.5).timeout
			overlay.aksi_selesai()
		_:
			await aksi_khusus(nama)


func aksi_khusus(_nama: String) -> void:   # di-override scene
	overlay.aksi_selesai()
	
func _atur_collision_act0() -> void:
	var act0: bool = GameProgress.tahap < GameProgress.Tahap.ACT1_MULAI
	for n in get_tree().get_nodes_in_group("collision_act0"):
		if n is TileMapLayer:
			n.collision_enabled = act0
		n.visible = act0 if n is CanvasItem and not (n is TileMapLayer) else n.visible
		n.process_mode = Node.PROCESS_MODE_INHERIT if act0 else Node.PROCESS_MODE_DISABLED
		for c in n.find_children("*", "CollisionShape2D", true, false):
			c.set_deferred("disabled", not act0)
		for c in n.find_children("*", "CollisionPolygon2D", true, false):
			c.set_deferred("disabled", not act0)
