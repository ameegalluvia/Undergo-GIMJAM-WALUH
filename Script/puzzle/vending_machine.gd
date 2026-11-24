extends Area2D

signal minuman_diambil(data_item: DataItem, jumlah_sekarang: int, batas: int)
signal cooldown_selesai

@export var item_minuman: DataItem               # isi DataItem minuman (dengan heal_sanity > 0)
@export var batas_minuman: int = 3
@export var durasi_cooldown: float = 60.0
@export var durasi_fade_mati: float = 0.25
@export var jeda_prompt_cooldown: float = 1.6   # jeda biar pesan "Minuman telah diambil" terbaca dulu
@export var durasi_petunjuk_inventory: float = 2.5
@export var lampu_target: CanvasItem              # misal PointLight2D atau node lampu lain
@export var suara_ambil: AudioStream
@export var suara_kosong_cooldown: AudioStream

@export var teks_siap := "Tekan E untuk mengambil minuman"
@export var teks_cooldown := "Vending machine sedang mengisi ulang (%ds)"
@export var pesan_batas := "Minuman telah mencapai batas"
@export var pesan_diambil := "Minuman telah diambil (%d/%d)"
@export var pesan_tidak_aktif := "Vending machine sedang tidak berfungsi."
@export var pesan_inventory_penuh := "Inventory penuh!"

var pemain_dekat := false
var sedang_cooldown := false
var sisa_cooldown := 0.0
var _sisa_jeda_prompt := 0.0
var _energi_awal: float = 1.0
var _tween_lampu: Tween

func _ready() -> void:
	if is_instance_valid(lampu_target) and "energy" in lampu_target:
		_energi_awal = lampu_target.energy

	body_entered.connect(_saat_body_masuk)
	body_exited.connect(_saat_body_keluar)

func _exit_tree() -> void:
	if is_instance_valid(InventoryUI):
		InventoryUI.sembunyikan_prompt(self)

func _process(delta: float) -> void:
	if not sedang_cooldown or get_tree().paused:
		return

	sisa_cooldown = maxf(0.0, sisa_cooldown - delta)
	if _sisa_jeda_prompt > 0.0:
		_sisa_jeda_prompt = maxf(0.0, _sisa_jeda_prompt - delta)

	if pemain_dekat and not Inventory.ui_terbuka:
		_perbarui_prompt()

	if sisa_cooldown <= 0.0:
		sedang_cooldown = false
		_sisa_jeda_prompt = 0.0
		_perbarui_prompt()
		cooldown_selesai.emit()

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

	if not SanityManager.aktif:
		InventoryUI.tampilkan_pesan(pesan_tidak_aktif, 2.0)
		return

	if sedang_cooldown:
		var detik := ceili(sisa_cooldown)
		InventoryUI.tampilkan_pesan("Masih mengisi ulang (%d detik)." % detik, 1.8)
		if suara_kosong_cooldown != null:
			AudioManager.play_sfx(suara_kosong_cooldown)
		return

	if item_minuman == null:
		push_warning("VendingMachine '%s' belum diisi 'item_minuman'" % name)
		return

	var jumlah_awal := _hitung_jumlah_minuman(item_minuman.id)
	if jumlah_awal >= batas_minuman:
		InventoryUI.tampilkan_pesan(pesan_batas, 2.5)
		return

	if Inventory.tambah_item(item_minuman):
		var jumlah_baru := _hitung_jumlah_minuman(item_minuman.id)
		if suara_ambil != null:
			AudioManager.play_sfx(suara_ambil)
		InventoryUI.tampilkan_pesan(pesan_diambil % [jumlah_baru, batas_minuman], 2.5)
		if is_instance_valid(InventoryUI):
			InventoryUI.tampilkan_petunjuk_inventory_sekali(durasi_petunjuk_inventory)
		minuman_diambil.emit(item_minuman, jumlah_baru, batas_minuman)
		_mulai_cooldown_dan_lampu()
	else:
		InventoryUI.tampilkan_pesan(pesan_inventory_penuh, 2.0)

func _hitung_jumlah_minuman(id_item: StringName) -> int:
	var total := 0
	if Inventory.item_dipegang != null and Inventory.item_dipegang.id == id_item:
		total += 1
	for item in Inventory.daftar_item:
		if item != null and item.id == id_item:
			total += 1
	return total

func _mulai_cooldown_dan_lampu() -> void:
	sedang_cooldown = true
	sisa_cooldown = durasi_cooldown
	_sisa_jeda_prompt = jeda_prompt_cooldown
	_perbarui_prompt()

	if _tween_lampu and _tween_lampu.is_running():
		_tween_lampu.kill()

	if is_instance_valid(lampu_target) and "energy" in lampu_target:
		_tween_lampu = create_tween()
		_tween_lampu.tween_property(lampu_target, "energy", 0.0, durasi_fade_mati)
		_tween_lampu.tween_property(lampu_target, "energy", _energi_awal, durasi_cooldown)

func _perbarui_prompt() -> void:
	if not pemain_dekat or not is_instance_valid(InventoryUI):
		return
	if sedang_cooldown and _sisa_jeda_prompt <= 0.0:
		InventoryUI.tampilkan_prompt(self, teks_cooldown % ceili(sisa_cooldown))
	else:
		InventoryUI.tampilkan_prompt(self, teks_siap)
