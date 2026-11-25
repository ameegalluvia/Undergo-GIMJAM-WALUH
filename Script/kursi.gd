extends Area2D

var dekat := false
var terpakai := false

func _ready() -> void:
	body_entered.connect(func(b): if b.is_in_group("player"): dekat = true; InventoryUI.tampilkan_prompt(self, "Tekan E untuk duduk"))
	body_exited.connect(func(b): if b.is_in_group("player"): dekat = false; InventoryUI.sembunyikan_prompt(self))

func _unhandled_input(event: InputEvent) -> void:
	if not dekat or terpakai or not event.is_action_pressed("interaksi"):
		return
	if Inventory.ui_terbuka or Transisi.sedang_transisi:
		return
	get_viewport().set_input_as_handled()
	terpakai = true
	InventoryUI.sembunyikan_prompt(self)
	get_parent().mulai_kursi()
