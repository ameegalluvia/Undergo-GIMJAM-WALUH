extends Node

@export var blip_bawaan: AudioStream = preload("res://assets/audio/tambahan/dialogue_blip.wav")   # sesuaikan path
@export var jeda_blip := 0.06          # detik antar bunyi
@export var volume_db := -6.0
@export var variasi_pitch := 0.08

var _player := AudioStreamPlayer.new()
var _berjalan := false
var _sisa := 0.0
var _stream: AudioStream


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player.bus = "SFX"
	add_child(_player)

var _sesi := 0

func mulai(durasi: float, khusus: AudioStream = null) -> void:
	_sesi += 1
	_stream = khusus if khusus else blip_bawaan
	_berjalan = true
	_sisa = durasi
	_bunyi()
	_loop(_sesi)


func berhenti() -> void:
	_sesi += 1          # matikan loop yang sedang berjalan
	_berjalan = false
	_player.stop()


func _loop(id: int) -> void:
	while _berjalan and _sisa > 0.0:
		await get_tree().create_timer(jeda_blip).timeout
		if id != _sesi:          # loop ini sudah usang, keluar
			return
		_sisa -= jeda_blip
		_bunyi()
	if id == _sesi:
		_berjalan = false


func _bunyi() -> void:
	if _stream == null:
		return
	_player.stream = _stream
	_player.volume_db = volume_db
	_player.pitch_scale = 1.0 + randf_range(-variasi_pitch, variasi_pitch)
	_player.play()
