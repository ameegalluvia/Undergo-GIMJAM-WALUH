extends Area2D

# Dipicu saat puzzle selesai, dan juga saat scene dimuat kalau puzzle ini sudah
# pernah selesai. [dengan_efek] false = sekadar pemulihan keadaan.
signal terbuka(dengan_efek: bool)

@export var item_dibutuhkan: DataItem            # kosong = tidak butuh item (misal saklar)
@export var habiskan_item := true
@export var teks_prompt := "Tekan E untuk membuka"
@export var pesan_butuh_item := "Sepertinya butuh sesuatu..."
@export var pesan_item_di_tas := "Sepertinya benda yang tepat ada di tasmu. Pegang dulu."
@export var pesan_berhasil := ""
@export var sembunyikan: Array[Node] = []        # hilang + tidak bisa ditabrak setelah terbuka
@export var tampilkan: Array[Node] = []          # tersembunyi dulu, muncul setelah terbuka
@export var id_puzzle: StringName                # boleh kosong, dibuat otomatis

var pemain_dekat := false
var sudah_terbuka := false

func _ready() -> void:
	if id_puzzle == &"":
		id_puzzle = StringName(str(get_path()))

	for n in tampilkan:
		_atur_aktif(n, false)

	if Inventory.id_terbuka.has(id_puzzle):
		_selesaikan(false)   # pulihkan keadaan terbuka tanpa efek
		return

	body_entered.connect(_saat_body_masuk)
	body_exited.connect(_saat_body_keluar)

func _exit_tree() -> void:
	if is_instance_valid(InventoryUI):
		InventoryUI.sembunyikan_prompt(self)

func _saat_body_masuk(body: Node2D) -> void:
	if body.is_in_group("player") and not sudah_terbuka:
		pemain_dekat = true
		InventoryUI.tampilkan_prompt(self, teks_prompt)

func _saat_body_keluar(body: Node2D) -> void:
	if body.is_in_group("player"):
		pemain_dekat = false
		InventoryUI.sembunyikan_prompt(self)

func _unhandled_input(event: InputEvent) -> void:
	if sudah_terbuka or not pemain_dekat or not event.is_action_pressed("interaksi"):
		return
	if Inventory.ui_terbuka:
		return
	get_viewport().set_input_as_handled()

	if item_dibutuhkan == null or Inventory.sedang_memegang(item_dibutuhkan.id):
		if item_dibutuhkan != null and habiskan_item:
			Inventory.habiskan_item_dipegang()
		_selesaikan(true)
	elif Inventory.punya_item(item_dibutuhkan.id):
		InventoryUI.tampilkan_pesan(pesan_item_di_tas, 3.0)
	else:
		InventoryUI.tampilkan_pesan(pesan_butuh_item, 3.0)

func _selesaikan(dengan_efek: bool) -> void:
	sudah_terbuka = true
	pemain_dekat = false
	if not Inventory.id_terbuka.has(id_puzzle):
		Inventory.id_terbuka.append(id_puzzle)

	for n in sembunyikan:
		_atur_aktif(n, false)
	for n in tampilkan:
		_atur_aktif(n, true)

	set_deferred("monitoring", false)
	InventoryUI.sembunyikan_prompt(self)
	terbuka.emit.call_deferred(dengan_efek)

	if dengan_efek and pesan_berhasil != "":
		InventoryUI.tampilkan_pesan(pesan_berhasil, 3.0)

# Menyalakan atau mematikan sebuah node beserta tabrakannya
func _atur_aktif(node: Node, aktif: bool) -> void:
	if not is_instance_valid(node):
		return
	if node is CanvasItem:
		node.visible = aktif
	if node is TileMapLayer:
		node.collision_enabled = aktif
	node.process_mode = Node.PROCESS_MODE_INHERIT if aktif else Node.PROCESS_MODE_DISABLED

	var bentuk: Array[Node] = node.find_children("*", "CollisionShape2D", true, false)
	bentuk.append_array(node.find_children("*", "CollisionPolygon2D", true, false))
	if node is CollisionShape2D or node is CollisionPolygon2D:
		bentuk.append(node)
	for b in bentuk:
		b.set_deferred("disabled", not aktif)
