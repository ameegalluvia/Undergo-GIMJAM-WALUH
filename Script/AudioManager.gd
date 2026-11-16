extends Node

# --- PENGATURAN BUS AUDIO ---
var master_bus: int
var music_bus: int
var sfx_bus: int

# --- PEMUTAR MUSIK (BGM) ---
var music_player: AudioStreamPlayer
var game_playlist: Array[AudioStream] = []
var current_track_index: int = 0
var is_playlist_active: bool = false

# --- POOL PEMUTAR SFX (Agar SFX bisa bunyi bersamaan tanpa terpotong) ===
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players: int = 8
var sfx_index: int = 0

# Menyimpan path scene sebelumnya agar tombol Back tahu harus kemana
var previous_scene_path: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 1. Inisialisasi Audio Bus
	master_bus = AudioServer.get_bus_index("Master")
	music_bus = AudioServer.get_bus_index("Music")
	sfx_bus = AudioServer.get_bus_index("SFX")
	
	# 2. Buat AudioStreamPlayer untuk Musik secara otomatis lewat kode
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)
	
	# 3. Buat beberapa AudioStreamPlayer untuk SFX (Audio Pooling)
	for i in range(max_sfx_players):
		var sfx = AudioStreamPlayer.new()
		sfx.bus = "SFX"
		add_child(sfx)
		sfx_players.append(sfx)

# ==========================================
# BAGIAN 1: SISTEM MUSIK (BGM)
# ==========================================

# Memutar musik tunggal (misal: lagu menu atau lagu boss)
func play_music(stream: AudioStream, fade_duration: float = 0.0) -> void:
	is_playlist_active = false
	if music_player.stream == stream and music_player.playing:
		return
	
	if fade_duration > 0.0:
		_fade_to_new_music(stream, fade_duration)
	else:
		music_player.stream = stream
		music_player.play()

# Memutar musik secara beruntun (Playlist dalam 1 scene)
func play_playlist(playlist: Array[AudioStream]) -> void:
	if playlist.is_empty():
		return
	game_playlist = playlist
	is_playlist_active = true
	current_track_index = 0
	music_player.stream = game_playlist[current_track_index]
	music_player.play()

func _on_music_finished() -> void:
	if not is_playlist_active or game_playlist.is_empty():
		return
	current_track_index = (current_track_index + 1) % game_playlist.size()
	music_player.stream = game_playlist[current_track_index]
	music_player.play()

func _fade_to_new_music(new_stream: AudioStream, duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -40.0, duration / 2)
	tween.tween_callback(func():
		music_player.stream = new_stream
		music_player.play()
	)
	tween.tween_property(music_player, "volume_db", 0.0, duration / 2)

func stop_music() -> void:
	is_playlist_active = false
	music_player.stop()


# ==========================================
# BAGIAN 2: SISTEM EFEK SUARA (SFX)
# ==========================================

# Memutar efek suara (bisa ditumpuk banyak sekaligus tanpa saling potong)
func play_sfx(stream: AudioStream) -> void:
	if not stream:
		return
	
	# Ambil pemutar SFX berikutnya dalam antrean (pooling)
	var sfx = sfx_players[sfx_index]
	sfx.stream = stream
	sfx.play()
	
	# Geser index ke pemutar berikutnya, putar kembali ke 0 jika habis
	sfx_index = (sfx_index + 1) % max_sfx_players


# ==========================================
# BAGIAN 3: PENGATURAN VOLUME (SETTING SCENE)
# ==========================================

func set_volume_linear(bus_name: String, linear_value: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_value))
		AudioServer.set_bus_mute(bus_idx, linear_value <= 0.01)

func get_volume_linear(bus_name: String) -> float:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	return 1.0
