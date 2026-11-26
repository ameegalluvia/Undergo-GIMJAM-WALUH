class_name player
extends CharacterBody2D

@export var speed: float = 100
@export var suara_langkah: Array[AudioStream] = []
@export var interval_langkah: float = 0.38
@export var volume_langkah_db: float = -6.0
@export var variasi_pitch: float = 0.08
@onready var senter: Node2D = $Senter
@onready var cahaya: PointLight2D = $Senter/Cahaya

var senter_menyala := false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var last_dir := "down"
var _timer_langkah: float = 0.0

func _ready() -> void:
	cahaya.enabled = false
	
func _update_senter() -> void:
	match last_dir:
		"right": senter.rotation_degrees = 0
		"down":  senter.rotation_degrees = 90
		"left":  senter.rotation_degrees = 180
		"up":    senter.rotation_degrees = 270

func toggle_senter() -> void:
	senter_menyala = not senter_menyala
	cahaya.enabled = senter_menyala
	

func _physics_process(delta: float) -> void:
	if Inventory.ui_terbuka or Transisi.sedang_transisi:
		velocity = Vector2.ZERO
		_timer_langkah = 0.0
		move_and_slide()
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()

	if direction == Vector2.ZERO:
		_timer_langkah = 0.0
		anim.play("idle_" + last_dir)
		return

	if abs(direction.x) > abs(direction.y):
		last_dir = "right" if direction.x > 0 else "left"
	else:
		last_dir = "down" if direction.y > 0 else "up"

	_update_senter()
	anim.play("walk_" + last_dir)
	_proses_footstep(delta)

	if Inventory.ui_terbuka:
		velocity = Vector2.ZERO
		_timer_langkah = 0.0
		move_and_slide()
		return

	if direction == Vector2.ZERO:
		_timer_langkah = 0.0
		anim.play("idle_" + last_dir)
		return

	if abs(direction.x) > abs(direction.y):
		last_dir = "right" if direction.x > 0 else "left"
	else:
		last_dir = "down" if direction.y > 0 else "up"

	anim.play("walk_" + last_dir)
	_proses_footstep(delta)

func _proses_footstep(delta: float) -> void:
	if suara_langkah.is_empty() or get_tree().paused:
		return

	if _timer_langkah <= 0.0:
		_putar_footstep()
		_timer_langkah = interval_langkah
	else:
		_timer_langkah -= delta

func _putar_footstep() -> void:
	var stream: AudioStream = suara_langkah.pick_random()
	if stream == null:
		return

	# Ambil player SFX berikutnya dari AudioManager lalu beri sedikit variasi pitch
	var idx := AudioManager.sfx_index
	AudioManager.play_sfx_volume(stream, volume_langkah_db)
	var sfx_player := AudioManager.sfx_players[idx]
	sfx_player.pitch_scale = randf_range(1.0 - variasi_pitch, 1.0 + variasi_pitch)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pakai_item") and not Inventory.ui_terbuka:
		Inventory.pakai_item_dipegang()
	if event.is_action_pressed("toggle_senter") and not Inventory.ui_terbuka:
		toggle_senter()

# Dipanggil scene saat Johan digerakkan otomatis
func main_jalan(arah: Vector2) -> void:
	if abs(arah.x) > abs(arah.y):
		last_dir = "right" if arah.x > 0 else "left"
	else:
		last_dir = "down" if arah.y > 0 else "up"
	_update_senter()
	anim.play("walk_" + last_dir)


func main_diam() -> void:
	anim.play("idle_" + last_dir)
