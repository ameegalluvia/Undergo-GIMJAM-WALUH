extends CanvasLayer

func _ready() -> void:
	visible = SanityManager.aktif
	SanityManager.aktif_berubah.connect(func(status: bool): visible = status)
