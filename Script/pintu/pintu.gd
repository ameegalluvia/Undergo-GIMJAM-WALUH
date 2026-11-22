extends Area2D

@export_file("*.tscn") var scene_tujuan: String
@export var id_titik_tujuan: StringName          # id Marker2D di scene tujuan
@export var teks_prompt := "Tekan E untuk membuka pintu"
@export var terkunci := false                    # true = tidak bisa dipakai
@export var pesan_terkunci := "Pintunya terkunci."
@export var suara_pintu: AudioStream             # opsional

var pemain_dekat := false

func _ready() -> void:
	body_entered.connect(_saat_body_masuk)
	body_exited.connect(_saat_body_keluar)

func _exit_tree() -> void:
	if is_instance_valid(InventoryUI):
		InventoryUI.sembunyikan_prompt(self)

func _saat_body_masuk(body: Node2D) -> void:
	if body.is_in_group("player"):
		pemain_dekat = true
		InventoryUI.tampilkan_prompt(self, teks_prompt)

func _saat_body_keluar(body: Node2D) -> void:
	if body.is_in_group("player"):
		pemain_dekat = false
		InventoryUI.sembunyikan_prompt(self)

func _unhandled_input(event: InputEvent) -> void:
	if not pemain_dekat or not event.is_action_pressed("interaksi"):
		return
	if Inventory.ui_terbuka or Transisi.sedang_transisi:
		return
	get_viewport().set_input_as_handled()

	if terkunci:
		InventoryUI.tampilkan_pesan(pesan_terkunci, 2.5)
		return
	if scene_tujuan.is_empty():
		push_warning("Pintu '%s' belum diisi scene tujuannya" % name)
		return

	InventoryUI.sembunyikan_prompt(self)
	AudioManager.play_sfx(suara_pintu)   # aman kalau kosong
	Transisi.pindah_scene(scene_tujuan, id_titik_tujuan)

# Dipakai kalau pintu ini nanti dibuka lewat puzzle (misalnya tiket)
func buka_kunci(_dengan_efek: bool = false) -> void:
	terkunci = false
