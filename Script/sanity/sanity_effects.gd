extends Node

# --- Referensi ---
@onready var glitch: ColorRect = $"../UI/Glitch"
# --- Pengaturan (Inspector) ---
@export var kurangi_kedip := false   # mode aman: efek lebih lemah

# Suara (boleh lebih dari satu file, dipilih acak)
@export var suara_bisikan: Array[AudioStream] = []
@export var suara_static: Array[AudioStream] = []
@export var suara_mati: AudioStream

@onready var subtitle: Label = $"../UI/Subtitle"

@export var teks_kuning := "Johan: Aduh, perasaanku gak enak..."
@export var teks_merah := "Johan: MANA OBAT! MANA OBAT!"
@export var durasi_subtitle := 3.0
@onready var sprite_normal: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var sprite_glitch: AnimatedSprite2D = $"../JohanGlitch"
@export_group("Audio Loop")
@export var loop_kuning: AudioStream
@export var loop_merah: AudioStream
@export var volume_loop_kuning_db := -14.0
@export var volume_loop_merah_db := -8.0
@export var fade_loop := 1.5

var loop_player := AudioStreamPlayer.new()
var tween_loop: Tween



var tween_subtitle: Tween

var timer_gangguan := Timer.new()
var timer_lampu := Timer.new()
var glitch_berjalan := false


func _ready() -> void:
	timer_gangguan.one_shot = true
	timer_gangguan.timeout.connect(_gangguan)
	add_child(timer_gangguan)

	timer_lampu.one_shot = true
	timer_lampu.timeout.connect(_lampu)
	add_child(timer_lampu)

	SanityManager.state_berubah.connect(_on_state)
	SanityManager.sanity_habis.connect(_on_mati)
	_on_state(SanityManager.state, SanityManager.state)
	_set_johan_glitch(SanityManager.johan_glitch and SanityManager.state >= SanityManager.State.MERAH)
	loop_player.bus = "SFX"
	loop_player.volume_db = -40.0
	add_child(loop_player)

# ---------- Perubahan state ----------
func _on_state(baru: int, lama: int) -> void:
	timer_gangguan.stop()
	timer_lampu.stop()
	_hentikan_glitch()
	_pulihkan_lampu()
	_atur_loop(baru)
	if baru != SanityManager.State.MERAH:
		_set_johan_glitch(false)
	if baru < SanityManager.State.MERAH:
		_set_johan_glitch(false)

	match baru:
		SanityManager.State.KUNING:
			_jadwalkan_gangguan()
			if lama == SanityManager.State.HIJAU:
				_tampil_subtitle(teks_kuning)
		SanityManager.State.MERAH:
			_jadwalkan_gangguan()
			_jadwalkan_lampu()
			_tampil_subtitle(teks_merah)


func _merah() -> bool:
	return SanityManager.state == SanityManager.State.MERAH


# ---------- Jadwal ----------
func _jadwalkan_gangguan() -> void:
	timer_gangguan.start(randf_range(8.0, 10.0) if _merah() else randf_range(7.0, 9.0))


func _jadwalkan_lampu() -> void:
	timer_lampu.start(randf_range(1.0, 3.0))


# ---------- Gangguan (KUNING dan MERAH) ----------
func _gangguan() -> void:
	if not SanityManager.aktif or get_tree().paused:
		_jadwalkan_gangguan()
		return

	_glitch()

	# Audio: bisikan atau static, lebih keras saat MERAH
	var volume := 0.0 if _merah() else -8.0
	var pilihan: Array[AudioStream] = suara_bisikan if randf() < 0.5 else suara_static
	if not pilihan.is_empty():
		AudioManager.play_sfx_volume(pilihan.pick_random(), volume)

	_jadwalkan_gangguan()
	
func _glitch() -> void:
	if glitch == null or glitch_berjalan:
		return
	var mat := glitch.material as ShaderMaterial
	if mat == null:
		return

	glitch_berjalan = true

	# KUNING: 1-2 kedip. MERAH: 2-3 kedip, tiap kedip lebih lama dan lebih kuat.
	var jumlah := randi_range(2, 3) if _merah() else randi_range(1, 2)
	var kuat_maks := 0.5 if kurangi_kedip else (1.0 if _merah() else 0.6)
	var lama_nyala_min := 0.25 if _merah() else 0.08
	var lama_nyala_max := 0.45 if _merah() else 0.16

	if _merah():
		_set_johan_glitch(not SanityManager.johan_glitch)

	glitch.visible = true
	for i in jumlah:
		if not glitch_berjalan:
			return
		mat.set_shader_parameter("benih", randf() * 100.0)
		mat.set_shader_parameter("intensitas", randf_range(0.8, 1.0) * kuat_maks)
		await get_tree().create_timer(randf_range(lama_nyala_min, lama_nyala_max)).timeout
		mat.set_shader_parameter("intensitas", 0.0)
		await get_tree().create_timer(randf_range(0.8, 1.4)).timeout   # jeda antar kedip

	_hentikan_glitch()


func _hentikan_glitch() -> void:
	glitch_berjalan = false
	if glitch:
		glitch.visible = false


# ---------- Lampu (hanya MERAH) ----------
func _lampu() -> void:
	if not _merah():
		return

	if randf() < 0.3:
		_lampu_mati_total(randf_range(2.0, 4.0))
	else:
		_lampu_berkedip()

	_jadwalkan_lampu()


func _energi_asli(lampu: Node) -> float:
	if not lampu.has_meta("energy_asli"):
		lampu.set_meta("energy_asli", lampu.energy)
	return lampu.get_meta("energy_asli")


func _lampu_berkedip() -> void:
	for lampu in get_tree().get_nodes_in_group("lampu_sanity"):
		var dasar := _energi_asli(lampu)
		var tw := create_tween()
		for i in 3:
			tw.tween_property(lampu, "energy", dasar * randf_range(0.0, 0.3), 0.08)
			tw.tween_property(lampu, "energy", dasar, 0.12)


func _lampu_mati_total(durasi: float) -> void:
	for lampu in get_tree().get_nodes_in_group("lampu_sanity"):
		var dasar := _energi_asli(lampu)
		var tw := create_tween()
		tw.tween_property(lampu, "energy", 0.0, 0.1)
		tw.tween_interval(durasi)
		tw.tween_property(lampu, "energy", dasar, 0.3)


func _pulihkan_lampu() -> void:
	for lampu in get_tree().get_nodes_in_group("lampu_sanity"):
		lampu.energy = _energi_asli(lampu)


# ---------- Mati ----------
func _on_mati() -> void:
	timer_gangguan.stop()
	timer_lampu.stop()
	_set_johan_glitch(true)
	get_parent().set_physics_process(false)   # Johan berhenti
	AudioManager.play_sfx(suara_mati)

	if glitch and glitch.material:
		glitch.visible = true
		(glitch.material as ShaderMaterial).set_shader_parameter("intensitas", 1.0)

	await get_tree().create_timer(2.5).timeout
	SaveManager.respawn()

func _tampil_subtitle(isi: String) -> void:
	if subtitle == null:
		return
	if tween_subtitle:
		tween_subtitle.kill()

	subtitle.text = isi
	subtitle.modulate.a = 0.0
	subtitle.visible = true

	tween_subtitle = create_tween()
	tween_subtitle.tween_property(subtitle, "modulate:a", 1.0, 0.2)
	tween_subtitle.tween_interval(durasi_subtitle)
	tween_subtitle.tween_property(subtitle, "modulate:a", 0.0, 0.4)
	tween_subtitle.tween_callback(func(): subtitle.visible = false)
	

func _set_johan_glitch(nyala: bool) -> void:
	SanityManager.johan_glitch = nyala
	if sprite_normal:
		sprite_normal.visible = not nyala
	if sprite_glitch:
		sprite_glitch.visible = nyala
		if nyala and sprite_normal:
			sprite_glitch.play(sprite_normal.animation)
			sprite_glitch.flip_h = sprite_normal.flip_h


func _sinkron_sprite() -> void:
	if SanityManager.johan_glitch and sprite_glitch and sprite_normal:
		if sprite_glitch.animation != sprite_normal.animation:
			sprite_glitch.play(sprite_normal.animation)
		sprite_glitch.flip_h = sprite_normal.flip_h
		sprite_glitch.frame = sprite_normal.frame


func _process(_delta: float) -> void:
	_sinkron_sprite()

func _atur_loop(baru: int) -> void:
	var stream: AudioStream = null
	var volume := 0.0
	match baru:
		SanityManager.State.KUNING:
			stream = loop_kuning
			volume = volume_loop_kuning_db
		SanityManager.State.MERAH:
			stream = loop_merah
			volume = volume_loop_merah_db

	if tween_loop:
		tween_loop.kill()
		tween_loop = null

	if stream == null:
		# HIJAU atau MATI: fade out lalu stop (hanya jika sedang main)
		if loop_player.playing:
			tween_loop = create_tween()
			tween_loop.tween_property(loop_player, "volume_db", -40.0, fade_loop)
			tween_loop.tween_callback(loop_player.stop)
		return

	tween_loop = create_tween()
	if loop_player.stream == stream and loop_player.playing:
		tween_loop.tween_property(loop_player, "volume_db", volume, fade_loop)
		return

	if loop_player.playing:
		tween_loop.tween_property(loop_player, "volume_db", -40.0, fade_loop * 0.5)
	tween_loop.tween_callback(func():
		loop_player.stream = stream
		loop_player.volume_db = -40.0
		loop_player.play())
	tween_loop.tween_property(loop_player, "volume_db", volume, fade_loop)
