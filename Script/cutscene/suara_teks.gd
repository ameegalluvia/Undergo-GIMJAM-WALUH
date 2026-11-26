extends Node

@export var blip_bawaan: AudioStream = preload("res://assets/audio/tambahan/dialogue_blip.wav")
@export var jeda_blip := 0.06          # detik antar bunyi
@export var volume_db := -6.0
@export var variasi_pitch := 0.08

var _player := AudioStreamPlayer.new()
var _berjalan := false
var _dijeda := false
var _sisa := 0.0
var _timer_blip := 0.0
var _stream: AudioStream


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player.bus = "SFX"
	add_child(_player)


func _process(delta: float) -> void:
	# Jangan kurangi durasi atau bunyikan blip jika sedang berhenti atau dijeda
	if not _berjalan or _dijeda:
		return

	_sisa -= delta
	if _sisa <= 0.0:
		berhenti()
		return

	_timer_blip -= delta
	if _timer_blip <= 0.0:
		_timer_blip = jeda_blip
		_bunyi()


func mulai(durasi: float, khusus: AudioStream = null) -> void:
	_stream = khusus if khusus else blip_bawaan
	_berjalan = true
	_dijeda = false
	_sisa = durasi
	_timer_blip = jeda_blip
	_bunyi()


func set_jeda(jeda: bool) -> void:
	_dijeda = jeda
	_player.stream_paused = jeda


func berhenti() -> void:
	_berjalan = false
	_dijeda = false
	_player.stop()


func _bunyi() -> void:
	if _stream == null:
		return
	_player.stream = _stream
	_player.volume_db = volume_db
	_player.pitch_scale = 1.0 + randf_range(-variasi_pitch, variasi_pitch)
	_player.play()
