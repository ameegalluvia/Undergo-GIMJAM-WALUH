extends Node2D

@export var peta: TileMapLayer
@export var tile_jangkar := Vector2i(3, 2)    # tile KIRI ATAS boneka utuh
@export var id_sumber := 0
@export var boneka_scene: PackedScene

# Offset sel dalam blok 2x2 -> atlas tile boneka hancur
@export var tile_hancur: Dictionary = {
	Vector2i(0, 0): Vector2i(18, 22),
	Vector2i(1, 0): Vector2i(19, 22),
	Vector2i(0, 1): Vector2i(18, 23),
	Vector2i(1, 1): Vector2i(19, 23),
}


func _ready() -> void:
	var i := 0
	var ukuran := Vector2(peta.tile_set.tile_size)
	for sel in peta.get_used_cells():
		if peta.get_cell_atlas_coords(sel) != tile_jangkar:
			continue
		var b = boneka_scene.instantiate()
		b.id_boneka = StringName("b%d" % i)
		b.name = "Boneka%d" % i
		b.peta = peta
		b.id_sumber = id_sumber
		b.sel_jangkar = sel
		b.tile_hancur = tile_hancur
		add_child(b)
		# Tengah blok 2x2 = pojok kiri atas sel jangkar + satu tile penuh
		var pojok := peta.to_global(peta.map_to_local(sel)) - ukuran * 0.5
		b.global_position = pojok + ukuran
		i += 1
	print("boneka ditemukan: ", i)   # harus 4
