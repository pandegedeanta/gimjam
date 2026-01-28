extends Area2D

@export var ui_node: CanvasLayer
@export var sprite: Sprite2D
@export var koordinat_buka: Rect2
@export var koordinat_tutup: Rect2
@export var jarak_toleransi: float = 150.0 
@export var next_scene_path: String = "res://scenes/area/parents_room.tscn"

var is_open: bool = false
var double_click_timer: float = 0.0

func _ready():
	# Memastikan hover tetap jalan
	mouse_entered.connect(func(): 
		sprite.modulate = Color(1.2, 1.2, 1.2)
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	)
	mouse_exited.connect(func(): 
		sprite.modulate = Color(1, 1, 1)
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().current_scene.find_child("Player", true, false)
		if not player: return

		# Cek Jarak Global agar akurat
		var dist = abs(player.global_position.x - self.global_position.x)
		if dist > jarak_toleransi:
			ui_node.show_message("Terlalu jauh...", Color.LIGHT_GRAY)
			return

		var current_time = Time.get_ticks_msec() / 1000.0
		
		# LOGIKA BARU:
		# 2x Klik = Masuk Ruangan
		if current_time - double_click_timer < 0.3:
			if is_open:
				masuk_ruangan()
			else:
				ui_node.show_message("Buka dulu pintunya baru bisa masuk.", Color.AQUAMARINE)
		
		# 1x Klik = Buka atau Tutup Pintu
		else:
			handle_toggle_visual()
		
		double_click_timer = current_time

func handle_toggle_visual():
	# Cek ketersediaan kunci di inventory
	if "Kunci Parents" in ui_node.inventory_items:
		is_open = !is_open
		# Mengatur Region Gambar secara manual dari script
		sprite.region_rect = koordinat_buka if is_open else koordinat_tutup
		ui_node.show_message("Pintu Terbuka" if is_open else "Pintu Ditutup", Color.AQUAMARINE)
	else:
		# Pesan seragam jika tidak ada kunci
		ui_node.show_message("Butuh kunci kamar orang tua.", Color.TOMATO)

func masuk_ruangan():
	ui_node.show_message("Memasuki kamar orang tua...", Color.WHITE)
	get_tree().change_scene_to_file(next_scene_path)
