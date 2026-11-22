extends Area2D

@export_file("*.tscn") var scene_tujuan: String
@export var id_titik_tujuan: StringName          # id Marker2D di scene tujuan
@export var teks_prompt := "Tekan E untuk membuka pintu"
@export var suara_pintu: AudioStream             # opsional

@export_group("Kunci")
@export var terkunci := false
@export var pesan_terkunci := "Pintunya terkunci."
@export var item_dibutuhkan: DataItem            # kosong = tidak bisa dibuka dengan item
@export var habiskan_item := true
@export var pesan_item_di_tas := "Sepertinya benda yang tepat ada di tasmu. Pegang dulu."
@export var pesan_dibuka := ""                   # misal "Pintu terbuka."
@export var id_pintu: StringName                 # boleh kosong, dibuat otomatis

var pemain_dekat := false

func _ready() -> void:
	if id_pintu == &"":
		id_pintu = StringName(str(get_path()))
	if Inventory.id_terbuka.has(id_pintu):
		terkunci = false   # pulihkan pintu yang sudah pernah dibuka

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
		_coba_buka_kunci()
		return
	if scene_tujuan.is_empty():
		push_warning("Pintu '%s' belum diisi scene tujuannya" % name)
		return

	InventoryUI.sembunyikan_prompt(self)
	AudioManager.play_sfx(suara_pintu)   # aman kalau kosong
	Transisi.pindah_scene(scene_tujuan, id_titik_tujuan)

func _coba_buka_kunci() -> void:
	if item_dibutuhkan == null:
		InventoryUI.tampilkan_pesan(pesan_terkunci, 2.5)
	elif Inventory.sedang_memegang(item_dibutuhkan.id):
		if habiskan_item:
			Inventory.habiskan_item_dipegang()
		buka_kunci()
		if pesan_dibuka != "":
			InventoryUI.tampilkan_pesan(pesan_dibuka, 2.5)
	elif Inventory.punya_item(item_dibutuhkan.id):
		InventoryUI.tampilkan_pesan(pesan_item_di_tas, 3.0)
	else:
		InventoryUI.tampilkan_pesan(pesan_terkunci, 2.5)

# Dipanggil saat item yang tepat dipakai, atau dari puzzle lain lewat signal
func buka_kunci(_dengan_efek: bool = false) -> void:
	terkunci = false
	if not Inventory.id_terbuka.has(id_pintu):
		Inventory.id_terbuka.append(id_pintu)
