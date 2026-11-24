extends Area2D

signal item_diambil(data_item: DataItem)

@export var item: DataItem                       # misal: palu.tres
@export var id_tempat: StringName                # boleh kosong, dibuat otomatis dari path

@export_group("Visual Tempat")
@export var node_ada_item: CanvasItem            # gambar/node tempat saat item masih ada
@export var node_kosong: CanvasItem              # gambar/node tempat setelah item diambil
@export var teks_prompt := "Tekan E untuk mengambil %s"
@export var teks_kosong := "Sudah kosong."

@export_group("Syarat Opsional")
@export var item_syarat: DataItem                # kosong = tidak butuh item syarat apa pun
@export var harus_dipegang := true               # true = harus sedang dipegang, false = cukup punya di tas
@export var pesan_syarat_gagal := "Sepertinya perlu sesuatu untuk mengeluarkannya..."

@export_group("Audio Opsional")
@export var suara_ambil: AudioStream

var pemain_dekat := false
var sudah_diambil := false

func _ready() -> void:
	if id_tempat == &"":
		id_tempat = StringName(str(get_path()))

	sudah_diambil = Inventory.id_terambil.has(id_tempat)
	_perbarui_visual()

	body_entered.connect(_saat_body_masuk)
	body_exited.connect(_saat_body_keluar)

func _exit_tree() -> void:
	if is_instance_valid(InventoryUI):
		InventoryUI.sembunyikan_prompt(self)

func _saat_body_masuk(body: Node2D) -> void:
	if body.is_in_group("player"):
		pemain_dekat = true
		_perbarui_prompt()

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

	if sudah_diambil:
		if teks_kosong != "":
			InventoryUI.tampilkan_pesan(teks_kosong, 2.0)
		return

	if item == null:
		push_warning("TempatItem '%s' belum diisi 'item' (DataItem)" % name)
		return

	if not _cek_syarat():
		InventoryUI.tampilkan_pesan(pesan_syarat_gagal, 2.5)
		return

	if Inventory.tambah_item(item):
		sudah_diambil = true
		if not Inventory.id_terambil.has(id_tempat):
			Inventory.id_terambil.append(id_tempat)
		_perbarui_visual()
		_perbarui_prompt()
		InventoryUI.umumkan_item_diambil(item)
		if suara_ambil != null:
			AudioManager.play_sfx(suara_ambil)
		item_diambil.emit(item)
	else:
		InventoryUI.tampilkan_pesan("Inventory penuh!", 2.0)

func _cek_syarat() -> bool:
	if item_syarat == null:
		return true
	if harus_dipegang:
		return Inventory.sedang_memegang(item_syarat.id)
	return Inventory.punya_item(item_syarat.id)

func _perbarui_visual() -> void:
	if is_instance_valid(node_ada_item):
		node_ada_item.visible = not sudah_diambil
	if is_instance_valid(node_kosong):
		node_kosong.visible = sudah_diambil

func _perbarui_prompt() -> void:
	if not pemain_dekat or not is_instance_valid(InventoryUI):
		return
	if sudah_diambil:
		InventoryUI.sembunyikan_prompt(self)
		return
	var nama := item.nama_tampil if item != null else "item"
	InventoryUI.tampilkan_prompt(self, teks_prompt % nama)
