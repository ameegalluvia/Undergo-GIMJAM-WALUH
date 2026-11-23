extends ColorRect

var tween: Tween


func _ready() -> void:
	SanityManager.sanity_berubah.connect(func(_n): _perbarui())
	SanityManager.aktif_berubah.connect(func(_s): _perbarui(true))
	_perbarui(true)


func _perbarui(langsung := false) -> void:
	var mat := material as ShaderMaterial
	if mat == null:
		return

	# 100 sanity = 0 (tidak ada), 0 sanity = 1 (paling gelap)
	var target := 0.0
	if SanityManager.aktif:
		target = 1.0 - SanityManager.nilai / SanityManager.MAKS
		target = pow(target, 1.3) * 0.95   # awal halus, makin ke bawah makin pekat
		
	var radius_target := lerpf(1.1, 0.55, 1.0 - SanityManager.nilai / SanityManager.MAKS) if SanityManager.aktif else 1.1
	mat.set_shader_parameter("radius", radius_target)

	if langsung:
		mat.set_shader_parameter("kekuatan", target)
		return

	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(mat, "shader_parameter/kekuatan", target, 0.5)
