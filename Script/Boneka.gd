extends Area2D

signal dihancurkan(boneka)

@export var berisi_kayu := false
@export var id_boneka: StringName
@export var peta: TileMapLayer
@export var id_sumber := 0
var sel_jangkar := Vector2i.ZERO
var tile_hancur: Dictionary = {}
var dekat := false
var hancur := false


func _ready() -> void:
	add_to_group("boneka")
	if id_boneka == &"":
		id_boneka = StringName(name)
	if GameProgress.ambil_flag("boneka_" + String(id_boneka)):
		_tampil_hancur()
		return
	body_entered.connect(_masuk)
	body_exited.connect(_keluar)


func _masuk(b: Node) -> void:
	if b.is_in_group("player") and not hancur:
		dekat = true
		InventoryUI.tampilkan_prompt(self, "Tekan E untuk menghancurkan")


func _keluar(b: Node) -> void:
	if b.is_in_group("player"):
		dekat = false
		InventoryUI.sembunyikan_prompt(self)


func _unhandled_input(event: InputEvent) -> void:
	if not dekat or hancur or not event.is_action_pressed("interaksi"):
		return
	if Inventory.ui_terbuka or Transisi.sedang_transisi:
		return
	if GameProgress.ambil_flag("dapat_kayu"):
		return
	get_viewport().set_input_as_handled()
	dekat = false
	InventoryUI.sembunyikan_prompt(self)
	GameProgress.set_flag("boneka_" + String(id_boneka))
	_tampil_hancur()
	dihancurkan.emit(self)

func _tampil_hancur() -> void:
	hancur = true
	monitoring = false
	if peta == null:
		return
	for offset in tile_hancur:
		peta.set_cell(sel_jangkar + offset, id_sumber, tile_hancur[offset])


func _exit_tree() -> void:
	if is_instance_valid(InventoryUI):
		InventoryUI.sembunyikan_prompt(self)
