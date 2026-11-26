extends Area2D

signal dipakai

var dekat := false


func _ready() -> void:
	body_entered.connect(func(b): if b.is_in_group("player"): dekat = true; _prompt())
	body_exited.connect(func(b): if b.is_in_group("player"): dekat = false; InventoryUI.sembunyikan_prompt(self))


func _prompt() -> void:
	if Inventory.punya_item(&"kaset"):
		InventoryUI.tampilkan_prompt(self, "Tekan E untuk memutar kaset")
	else:
		InventoryUI.tampilkan_prompt(self, "Komputer")


func _unhandled_input(event: InputEvent) -> void:
	if not dekat or not event.is_action_pressed("interaksi"):
		return
	if Inventory.ui_terbuka or Transisi.sedang_transisi:
		return
	get_viewport().set_input_as_handled()
	if Inventory.punya_item(&"kaset"):
		InventoryUI.sembunyikan_prompt(self)
		dekat = false
		dipakai.emit()
	else:
		InventoryUI.tampilkan_pesan("Tidak ada yang bisa diputar.", 2.0)


func _exit_tree() -> void:
	if is_instance_valid(InventoryUI):
		InventoryUI.sembunyikan_prompt(self)
