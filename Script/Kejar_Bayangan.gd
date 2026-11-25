extends Node

@onready var lorong = get_parent()
@onready var bayangan: AnimatedSprite2D = lorong.get_node("Bayangan")
@onready var pembatas: StaticBody2D = $Pembatas
@onready var titik := [$Titik1, $Titik2, $Titik3]
@onready var sensor := [$DekatTitik1, $DekatTitik2, $DekatTitik3]
@onready var titik_studio3: Marker2D = $Titikstudio3

var tahap_kejar := 0   # 0 sampai 2


func _ready() -> void:
	var aktif: bool = GameProgress.tahap == GameProgress.Tahap.ACT1_KEJAR
	_set_pembatas(aktif)
	for s in sensor:
		s.monitoring = false
	if not aktif:
		return
	for i in sensor.size():
		sensor[i].body_entered.connect(_on_dekat.bind(i))

	# Lanjut dari simpanan kalau ada
		tahap_kejar = int(GameProgress.ambil_flag("kejar_tahap", 0))
	if tahap_kejar >= 3:
		return
	await get_tree().process_frame
	_tampilkan_bayangan(tahap_kejar)
	


func _set_pembatas(nyala: bool) -> void:
	pembatas.visible = nyala
	for c in pembatas.get_children():
		if c is CollisionShape2D:
			c.set_deferred("disabled", not nyala)


# Bayangan berdiri menunggu di titik ke-i, sensor aktif
func _tampilkan_bayangan(i: int) -> void:
	bayangan.global_position = titik[i].global_position
	bayangan.visible = true
	if bayangan.sprite_frames.has_animation("idle_down"):
		bayangan.play("idle_down")
	# aktifkan sensor setelah fisika siap, cek yang sudah di dalam
	sensor[i].set_deferred("monitoring", true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	for b in sensor[i].get_overlapping_bodies():
		_on_dekat(b, i)


func _on_dekat(body: Node, i: int) -> void:
	if not body.is_in_group("player"):
		return
	if i != tahap_kejar:
		return
	sensor[i].set_deferred("monitoring", false)
	lorong._kunci_pemain(true)
	var kunci: String = ["cs_kejar1", "cs_kejar2", "cs_kejar3"][i]
	var data: CutsceneData = load("res://Data/Cutscene/act1_kejar%d.tres" % (i + 1))
	lorong.mainkan_sekali(kunci, data)
	
	
func lanjut_setelah_dialog() -> void:
	tahap_kejar += 1
	GameProgress.set_flag("kejar_tahap", tahap_kejar)
	SaveManager.simpan_scene(lorong.scene_file_path)
	if tahap_kejar < 3:
		lorong._kunci_pemain(false)
		_tampilkan_bayangan(tahap_kejar)
	else:
		_selesai_kejar()


func bayangan_kabur() -> void:
	var tujuan: Vector2
	if tahap_kejar >= 2:
		tujuan = titik_studio3.global_position   # tangkap kedua: masuk studio 3
	else:
		tujuan = titik[tahap_kejar + 1].global_position

	var arah: Vector2 = tujuan - bayangan.global_position
	var sisi := "right" if arah.x > 0 else "left"
	if abs(arah.y) > abs(arah.x):
		sisi = "down" if arah.y > 0 else "up"
	if bayangan.sprite_frames.has_animation("walk_" + sisi):
		bayangan.play("walk_" + sisi)

	var tw := create_tween()
	tw.tween_property(bayangan, "global_position", tujuan, max(arah.length(), 1.0) / 120.0)
	await tw.finished
	if tahap_kejar >= 2:
		bayangan.visible = false


func _selesai_kejar() -> void:
	_set_pembatas(false)
	GameProgress.tahap = GameProgress.Tahap.ACT1_STUDIO3
	GameProgress.set_flag("studio3_terbuka")
	lorong.get_node("Pintu/PintuStudio/PintuStudio4/PintuKeStudio4").terkunci = false   # sesuaikan nama pintu
	SaveManager.simpan_scene(lorong.scene_file_path)
	lorong._kunci_pemain(false)
	
