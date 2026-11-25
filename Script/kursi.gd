extends Area2D

var dekat := false


func _ready() -> void:
	body_entered.connect(_masuk)
	body_exited.connect(_keluar)
	if _sudah_dipakai():
		monitoring = false


func _sudah_dipakai() -> bool:
	return GameProgress.ambil_flag("memori1_selesai") or GameProgress.ambil_flag("cs_kursi")


func _masuk(b: Node) -> void:
	if b.is_in_group("player") and not _sudah_dipakai():
		dekat = true
		InventoryUI.tampilkan_prompt(self, "Tekan E untuk duduk")


func _keluar(b: Node) -> void:
	if b.is_in_group("player"):
		dekat = false
		InventoryUI.sembunyikan_prompt(self)


func _unhandled_input(event: InputEvent) -> void:
	if not dekat or _sudah_dipakai() or not event.is_action_pressed("interaksi"):
		return
	if Inventory.ui_terbuka or Transisi.sedang_transisi:
		return
	if _sudah_dipakai():
		InventoryUI.tampilkan_pesan("Aku sudah menonton ini.", 2.0)
		return
	get_viewport().set_input_as_handled()
	dekat = false
	InventoryUI.sembunyikan_prompt(self)
	get_parent().mulai_kursi()


func _exit_tree() -> void:
	if is_instance_valid(InventoryUI):
		InventoryUI.sembunyikan_prompt(self)
