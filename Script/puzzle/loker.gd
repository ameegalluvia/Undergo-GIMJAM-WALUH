extends Area2D

signal status_berubah(terbuka: bool)

@export var node_tutup: CanvasItem
@export var node_buka: CanvasItem
@export var item_pickup: Area2D          # opsional: node pickup item di dalam loker
@export var suara_buka: AudioStream      # opsional: SFX saat loker dibuka
@export var suara_tutup: AudioStream     # opsional: SFX saat loker ditutup
@export var teks_buka := "Tekan E untuk membuka loker"
@export var teks_tutup := "Tekan E untuk menutup loker"
@export var mulai_terbuka := false

var pemain_dekat := false
var terbuka := false

func _ready() -> void:
	_terapkan_keadaan(mulai_terbuka, true)
	body_entered.connect(_saat_body_masuk)
	body_exited.connect(_saat_body_keluar)

func _exit_tree() -> void:
	if is_instance_valid(InventoryUI):
		InventoryUI.sembunyikan_prompt(self)
		if item_pickup != null:
			InventoryUI.sembunyikan_prompt(item_pickup)

func _saat_body_masuk(body: Node2D) -> void:
	if body.is_in_group("player"):
		pemain_dekat = true
		_perbarui_prompt_loker()

func _saat_body_keluar(body: Node2D) -> void:
	if body.is_in_group("player"):
		pemain_dekat = false
		InventoryUI.sembunyikan_prompt(self)

func _unhandled_input(event: InputEvent) -> void:
	if not pemain_dekat or not event.is_action_pressed("interaksi"):
		return
	if Inventory.ui_terbuka:
		return

	get_viewport().set_input_as_handled()
	_terapkan_keadaan(not terbuka, false)
	_perbarui_prompt_loker()

func _terapkan_keadaan(nilai_terbuka: bool, saat_awal: bool) -> void:
	terbuka = nilai_terbuka

	if is_instance_valid(node_tutup):
		node_tutup.visible = not terbuka
	if is_instance_valid(node_buka):
		node_buka.visible = terbuka

	_perbarui_item_pickup()

	if not saat_awal:
		var sfx := suara_buka if terbuka else suara_tutup
		if sfx != null:
			AudioManager.play_sfx(sfx)
		status_berubah.emit(terbuka)

func _perbarui_item_pickup() -> void:
	if not is_instance_valid(item_pickup):
		return

	var sudah_diambil := false
	if "id_pickup" in item_pickup and item_pickup.id_pickup != &"":
		sudah_diambil = Inventory.id_terambil.has(item_pickup.id_pickup)
	elif "id_pickup" in item_pickup:
		sudah_diambil = Inventory.id_terambil.has(StringName(str(item_pickup.get_path())))

	var boleh_muncul := terbuka and not sudah_diambil

	if item_pickup is CanvasItem:
		item_pickup.visible = boleh_muncul
	item_pickup.process_mode = Node.PROCESS_MODE_INHERIT if boleh_muncul else Node.PROCESS_MODE_DISABLED
	item_pickup.set_deferred("monitoring", boleh_muncul)
	item_pickup.set_deferred("monitorable", boleh_muncul)

	if not boleh_muncul and is_instance_valid(InventoryUI):
		InventoryUI.sembunyikan_prompt(item_pickup)

func _perbarui_prompt_loker() -> void:
	if not pemain_dekat or not is_instance_valid(InventoryUI):
		return
	var teks := teks_tutup if terbuka else teks_buka
	InventoryUI.tampilkan_prompt(self, teks)
