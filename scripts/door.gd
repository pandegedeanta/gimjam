extends Area2D

@export var sprite: Sprite2D
@export var laci: Area2D # Nanti tarik node Drawer ke sini
@export var dist_klik: float = 150.0

# Koordinat gambar pintu (isi di Inspector)
@export var koordinat_tutup: Rect2
@export var koordinat_buka: Rect2

var sudah_terbuka = false

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		var player = get_tree().current_scene.find_child("Player", true, false)
		
		if player:
			# Hitung jarak asli antara badan player dan pintu
			var jarak = abs(global_position.x - player.global_position.x)
			
			if jarak <= dist_klik:
				buka_pintu()
			else:
				print("Kejauhan! Jarakmu: ", jarak)

func buka_pintu():
	if sudah_terbuka: return

	# Tanya ke laci: "Kuncinya sudah diambil?"
	if laci and laci.item_taken == true:
		print("Pintu Terbuka!")
		sudah_terbuka = true
		sprite.region_rect = koordinat_buka
	else:
		print("Gak bisa buka, kuncinya belum diambil di laci!")
