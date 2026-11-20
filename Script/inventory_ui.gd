extends CanvasLayer

const DASAR := "Overlay/CenterContainer/Panel/MarginContainer/VBoxContainer/"

@onready var ikon_tangan: TextureRect = $HeldIcon
@onready var overlay: Control = $Overlay
@onready var label_tangan: Label = get_node(DASAR + "HandLabel")
@onready var grid: GridContainer = get_node(DASAR + "Grid")
@onready var bar_aksi: HBoxContainer = get_node(DASAR + "ActionBar")
@onready var tombol_gunakan: Button = get_node(DASAR + "ActionBar/UseButton")
@onready var tombol_batal: Button = get_node(DASAR + "ActionBar/CancelButton")

@onready var label_prompt: Label = $PromptLabel
@onready var label_petunjuk: Label = $HintLabel

var pemilik_prompt: Node = null       # pickup mana yang sedang menampilkan prompt
var petunjuk_inventory_sudah := false # petunjuk Inventory cukup muncul sekali

var daftar_slot: Array[SlotInventory] = []
var indeks_terpilih := -1

var antrean_pesan: Array = []
var pesan_aktif := false
var sisa_pesan := 0.0
var tag_aktif: StringName = &""

func _ready() -> void:
	label_prompt.hide()
	label_petunjuk.hide()
	
	overlay.hide()
	bar_aksi.hide()

	for i in Inventory.MAKS_SLOT:
		var slot := SlotInventory.new()
		grid.add_child(slot)
		slot.pressed.connect(_saat_slot_ditekan.bind(i))
		daftar_slot.append(slot)

	tombol_gunakan.pressed.connect(_saat_gunakan_ditekan)
	tombol_batal.pressed.connect(_hapus_pilihan)
	Inventory.berubah.connect(_segarkan)
	_segarkan()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if overlay.visible:
			tutup()
		elif _boleh_dibuka():
			buka()
		else:
			return
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_cancel") and overlay.visible:
		if indeks_terpilih != -1:
			_hapus_pilihan()
		else:
			tutup()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	label_prompt.visible = pemilik_prompt != null and not Inventory.ui_terbuka and not get_tree().paused

	if pesan_aktif:
		sisa_pesan -= delta
		if sisa_pesan <= 0.0:
			_pesan_berikutnya()
	# Ikon di tangan hanya tampil kalau memegang item dan game tidak sedang di-pause
	ikon_tangan.visible = Inventory.item_dipegang != null and not get_tree().paused

func _boleh_dibuka() -> bool:
	if get_tree().paused:   # tidak bisa dibuka saat pause menu aktif
		return false
	var scene := get_tree().current_scene
	if scene == null:
		return false
	var path := scene.scene_file_path
	return not (path.contains("main_menu.tscn") or path.contains("settings.tscn"))

func buka() -> void:
	Inventory.ui_terbuka = true
	hapus_pesan_bertag(&"inventory")
	overlay.show()
	_hapus_pilihan()

func tutup() -> void:
	Inventory.ui_terbuka = false
	overlay.hide()

func _segarkan() -> void:
	var dipegang := Inventory.item_dipegang
	ikon_tangan.texture = dipegang.ikon if dipegang else null
	label_tangan.text = "Di tangan: " + (dipegang.nama_tampil if dipegang else "-")

	for i in daftar_slot.size():
		var item: DataItem = Inventory.daftar_item[i] if i < Inventory.daftar_item.size() else null
		daftar_slot[i].atur_item(item)
		daftar_slot[i].atur_terpilih(i == indeks_terpilih)

func _saat_slot_ditekan(indeks: int) -> void:
	indeks_terpilih = indeks
	bar_aksi.show()
	_segarkan()

func _saat_gunakan_ditekan() -> void:
	if indeks_terpilih != -1:
		Inventory.tukar_dengan_tangan(indeks_terpilih)
		SaveManager.simpan_inventory()   # BARU
	_hapus_pilihan()

func _hapus_pilihan() -> void:
	indeks_terpilih = -1
	bar_aksi.hide()
	_segarkan()

# HINT FOR INVENTORY
func tampilkan_prompt(pemilik: Node, teks: String) -> void:
	pemilik_prompt = pemilik
	label_prompt.text = teks

func sembunyikan_prompt(pemilik: Node) -> void:
	# hanya pemilik prompt yang boleh menyembunyikannya
	if pemilik_prompt == pemilik:
		pemilik_prompt = null
		
# Tambah pesan ke antrean. Pesan tampil satu per satu sesuai urutan masuk.
func tampilkan_pesan(teks: String, durasi: float = 3.0, tag: StringName = &"") -> void:
	antrean_pesan.append({"teks": teks, "durasi": durasi, "tag": tag})
	if not pesan_aktif:
		_pesan_berikutnya()

func _pesan_berikutnya() -> void:
	if antrean_pesan.is_empty():
		pesan_aktif = false
		tag_aktif = &""
		label_petunjuk.hide()
		return
	var pesan: Dictionary = antrean_pesan.pop_front()
	pesan_aktif = true
	sisa_pesan = pesan["durasi"]
	tag_aktif = pesan["tag"]
	label_petunjuk.text = pesan["teks"]
	label_petunjuk.show()

# Buang pesan bertag tertentu (yang sedang tampil langsung dilewati)
func hapus_pesan_bertag(tag: StringName) -> void:
	antrean_pesan = antrean_pesan.filter(func(p: Dictionary) -> bool: return p["tag"] != tag)
	if pesan_aktif and tag_aktif == tag:
		_pesan_berikutnya()

# Dipanggil pickup setelah item berhasil diambil
func umumkan_item_diambil(item: DataItem) -> void:
	tampilkan_pesan(item.nama_tampil + " telah diambil", 2.5)
	if not petunjuk_inventory_sudah:
		petunjuk_inventory_sudah = true
		tampilkan_pesan("Tekan Tab atau I untuk membuka Inventory", 5.0, &"inventory")
