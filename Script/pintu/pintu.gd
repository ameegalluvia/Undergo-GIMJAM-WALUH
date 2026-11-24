extends Area2D

@export_file("*.tscn") var scene_tujuan: String
@export var id_titik_tujuan: StringName          # id Marker2D di scene tujuan
@export var teks_prompt := "Tekan E untuk membuka pintu"
@export var suara_pintu: AudioStream             # opsional

@export_group("Kunci")
@export var terkunci := false
@export var suara_terkunci: AudioStream          # BARU: bunyi saat pintu terkunci dicoba dibuka
@export var suara_kunci_dibuka: AudioStream      # BARU (opsional): bunyi saat kunci berhasil dibuka
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

var _bunyi_berikut_ms := 0

func _coba_buka_kunci() -> void:
	if item_dibutuhkan == null:
		_gagal(pesan_terkunci)
	elif Inventory.sedang_memegang(item_dibutuhkan.id):
		if habiskan_item:
			Inventory.habiskan_item_dipegang()
		AudioManager.play_sfx(suara_kunci_dibuka)   # aman kalau kosong
		buka_kunci()
		if pesan_dibuka != "":
			InventoryUI.tampilkan_pesan(pesan_dibuka, 2.5)
	elif Inventory.punya_item(item_dibutuhkan.id):
		_gagal(pesan_item_di_tas, 3.0)
	else:
		_gagal(pesan_terkunci)

# Bunyi terkunci + pesan. Ada jeda singkat supaya menekan E cepat-cepat tidak memicu bunyi bertumpuk.
func _gagal(pesan: String, durasi: float = 2.5) -> void:
	var sekarang := Time.get_ticks_msec()
	if sekarang >= _bunyi_berikut_ms:
		AudioManager.play_sfx(suara_terkunci)
		_bunyi_berikut_ms = sekarang + 500
	InventoryUI.tampilkan_pesan(pesan, durasi)

# Dipanggil saat item yang tepat dipakai, atau dari puzzle lain lewat signal
func buka_kunci(_dengan_efek: bool = false) -> void:
	terkunci = false
	if not Inventory.id_terbuka.has(id_pintu):
		Inventory.id_terbuka.append(id_pintu)
