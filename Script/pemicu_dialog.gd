extends Area2D

signal selesai(id: String)

@export var id_dialog: String = ""
@export var data: CutsceneData
@export var sekali := true
@export var syarat_flag: String = ""      # kosong = tanpa syarat
@export var flag_dilarang: String = ""    # tidak aktif jika flag ini sudah ada
@export var tahap_minimal := 0

var lorong_adegan: AdeganBase


func _ready() -> void:
	body_entered.connect(_masuk)


func _masuk(b: Node) -> void:
	if not b.is_in_group("player"):
		return
	if GameProgress.tahap < tahap_minimal:
		return
	if syarat_flag != "" and not GameProgress.ambil_flag(syarat_flag):
		return
	if flag_dilarang != "" and GameProgress.ambil_flag(flag_dilarang):
		return
	var adegan := owner as AdeganBase
	if adegan == null:
		return
	if sekali and GameProgress.ambil_flag(id_dialog):
		return
	adegan._kunci_pemain(true)
	adegan.mainkan_sekali(id_dialog, data)
