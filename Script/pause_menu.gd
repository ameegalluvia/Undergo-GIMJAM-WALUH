extends CanvasLayer

const SETTINGS_SCENE := preload("res://Scene/sistem/settings.tscn")
var settings_instance: Control = null

@onready var confirm_overlay: Control = $ConfirmOverlay
@onready var message_label: Label = $ConfirmOverlay/CenterContainer/Panel/MarginContainer/VBoxContainer/MessageLabel
@onready var yes_button: Button = $ConfirmOverlay/CenterContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/YesButton
@onready var no_button: Button = $ConfirmOverlay/CenterContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/NoButton

var pending_action: Callable

func _ready() -> void:
	hide()
	confirm_overlay.hide()
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_close_confirm)

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	# Inventory menangani ESC-nya sendiri
	if Inventory.ui_terbuka:
		return

	# 1. Konfirmasi terbuka: ESC = batal
	if confirm_overlay.visible:
		_close_confirm()
		get_viewport().set_input_as_handled()
		return

	# 2. Settings overlay terbuka: ESC = kembali ke pause menu
	if is_instance_valid(settings_instance):
		settings_instance.close()
		get_viewport().set_input_as_handled()
		return

	# 3. Abaikan ESC di scene non-gameplay
	var path := get_tree().current_scene.scene_file_path
	if path.contains("main_menu.tscn") or path.contains("settings.tscn"):
		return

	toggle_pause()
	get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	if get_tree().paused:
		resume_game()
	else:
		pause_game()

func pause_game() -> void:
	get_tree().paused = true
	show()

func resume_game() -> void:
	get_tree().paused = false
	confirm_overlay.hide()
	hide()

# --- Konfirmasi ---

func _ask_confirm(message: String, action: Callable) -> void:
	pending_action = action
	message_label.text = message
	confirm_overlay.show()

func _close_confirm() -> void:
	confirm_overlay.hide()
	pending_action = Callable()

func _on_yes_pressed() -> void:
	confirm_overlay.hide()
	if pending_action.is_valid():
		pending_action.call()
	pending_action = Callable()

# --- Tombol pause menu ---

func _on_resume_pressed() -> void:
	resume_game()

func _on_restart_pressed() -> void:
	_ask_confirm("Yakin mau restart? \n Progres level ini akan hilang", _do_restart)

func _do_restart() -> void:
	SaveManager.pulihkan_inventory()
	InventoryUI.bersihkan_pesan()
	resume_game()
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	_ask_confirm("Yakin kembali ke Main Menu? \n Progres akan hilang", _do_main_menu)

func _do_main_menu() -> void:
	Inventory.reset()
	InventoryUI.bersihkan_pesan()
	resume_game()
	get_tree().change_scene_to_file("res://Scene/sistem/main_menu.tscn")

# --- Settings overlay ---

func _on_settings_pressed() -> void:
	settings_instance = SETTINGS_SCENE.instantiate()
	settings_instance.as_overlay = true
	settings_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(settings_instance)
	settings_instance.closed.connect(_on_settings_closed)
	_set_menu_visible(false)

func _on_settings_closed() -> void:
	settings_instance = null
	_set_menu_visible(true)

func _set_menu_visible(value: bool) -> void:
	for c in get_children():
		if c is CanvasItem and c != settings_instance and c != confirm_overlay:
			c.visible = value
