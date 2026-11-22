class_name player
extends CharacterBody2D

@export var speed: float = 100.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var last_dir := "down"

func _physics_process(_delta: float) -> void:
	if Inventory.ui_terbuka or Transisi.sedang_transisi:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if Inventory.ui_terbuka:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()

	if direction == Vector2.ZERO:
		anim.play("idle_" + last_dir)
		return

	if abs(direction.x) > abs(direction.y):
		last_dir = "right" if direction.x > 0 else "left"
	else:
		last_dir = "down" if direction.y > 0 else "up"

	anim.play("walk_" + last_dir)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1: SanityManager.kurangi(20)
		if event.keycode == KEY_2: SanityManager.tambah(20)
