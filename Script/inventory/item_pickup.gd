extends Area2D

@export var item: DataItem
@export var id_pickup: StringName            # boleh kosong, nanti dibuat otomatis
@export var ukuran_di_dunia := 16         # sisi terpanjang gambar di dunia, dalam piksel
@export var durasi_petunjuk_inventory: float = 2.5

var pemain_dekat := false

func _ready() -> void:
	if id_pickup == &"":
		id_pickup = StringName(str(get_path()))
	if Inventory.id_terambil.has(id_pickup):
		queue_free()
		return

	if item and item.ikon:
		var sprite: Sprite2D = $Sprite2D
		sprite.texture = item.ikon
		var ukuran := item.ikon.get_size()
		var skala := ukuran_di_dunia / maxf(ukuran.x, ukuran.y)
		sprite.scale = Vector2(skala, skala)

	body_entered.connect(_saat_body_masuk)
	body_exited.connect(_saat_body_keluar)

func _exit_tree() -> void:
	# jaga-jaga kalau pickup hilang saat prompt masih tampil (restart, pindah scene)
	if is_instance_valid(InventoryUI):
		InventoryUI.sembunyikan_prompt(self)

func _saat_body_masuk(body: Node2D) -> void:
	if body.is_in_group("player"):
		pemain_dekat = true
		InventoryUI.tampilkan_prompt(self, "Tekan E untuk ambil " + item.nama_tampil)

func _saat_body_keluar(body: Node2D) -> void:
	if body.is_in_group("player"):
		pemain_dekat = false
		InventoryUI.sembunyikan_prompt(self)

func _unhandled_input(event: InputEvent) -> void:
	if not (pemain_dekat and event.is_action_pressed("interaksi")):
		return
	if Inventory.ui_terbuka:
		return
	if Inventory.tambah_item(item):
		Inventory.id_terambil.append(id_pickup)
		InventoryUI.sembunyikan_prompt(self)
		InventoryUI.umumkan_item_diambil(item)
		if is_instance_valid(InventoryUI):
			InventoryUI.tampilkan_petunjuk_inventory_sekali(durasi_petunjuk_inventory)
		get_viewport().set_input_as_handled()
		queue_free()
	else:
		InventoryUI.tampilkan_pesan("Inventory penuh!", 2.0)
