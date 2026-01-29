extends Area2D

@export_group("UI & Visual")
@export var ui_node: CanvasLayer
@export var sprite: Sprite2D       # Node Pintu
@export var wood_sprite: Sprite2D  # Node Kayu (Drag node kayu kesini di Inspector)
@export var wall_collision: StaticBody2D
@export var koordinat_buka: Rect2
@export var koordinat_tutup: Rect2 
@export var jarak_toleransi: float = 128.0

@export_group("Room Darkeners")
@export var parents_room_darkener: ColorRect
@export var hall_darkener: ColorRect        

@export_group("Light Clipping")
@export var parents_light_frame: Control

@export_group("Interaction Settings")
@export var item_perusak: String = "Palu"
@export var door_x_min: float = 1800.0
@export var door_x_max: float = 1950.0

@export_group("Teleport Settings")
@export_file("*.tscn") var scene_dalam_kamar # Scene tujuan saat masuk
@export var spawn_pos_kamar: Vector2 = Vector2.ZERO # Posisi spawn di kamar

var sudah_jebol: bool = false 
var is_open: bool = false

func _ready():
	# 1. Cek progres dari Global
	var saved = Global.get_state(self.name)
	if saved:
		sudah_jebol = saved.get("unlocked", false)
		# Jika sudah jebol, sembunyikan kayu selamanya
		if wood_sprite: wood_sprite.visible = not sudah_jebol
		
		# Load status pintu terbuka/tertutup
		is_open = saved.get("is_open", false)
		if is_open:
			sprite.region_rect = koordinat_buka
			if wall_collision: wall_collision.set_collision_layer_value(1, false)
			_set_lights_clipping(false)
	else:
		# Default awal: Kayu muncul
		if wood_sprite: wood_sprite.visible = true

	# 2. Hover Visual (GABUNGAN PINTU & KAYU)
	mouse_entered.connect(_on_mouse_enter)
	mouse_exited.connect(_on_mouse_exit)
	
	# 3. Setup Collision Awal
	if wall_collision and not is_open: 
		wall_collision.set_collision_layer_value(1, true)
	
	_set_lights_clipping(not is_open)

# --- FUNGSI HOVER BARU ---
func _on_mouse_enter():
	# Highlight Pintu
	if sprite: sprite.modulate = Color(1.2, 1.2, 1.2)
	# Highlight Kayu (hanya jika kayu masih ada/visible)
	if wood_sprite and wood_sprite.visible: 
		wood_sprite.modulate = Color(1.2, 1.2, 1.2)
	
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exit():
	# Reset Warna Pintu
	if sprite: sprite.modulate = Color(1, 1, 1)
	# Reset Warna Kayu
	if wood_sprite: wood_sprite.modulate = Color(1, 1, 1)
	
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

# --- LOGIKA KLIK & DOUBLE CLICK ---
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().current_scene.find_child("Player", true, false)
		if not player: return
		
		# Cek Jarak
		if abs(player.global_position.x - self.global_position.x) > jarak_toleransi:
			ui_node.show_message("Terlalu jauh...", Color.LIGHT_GRAY)
			return
			
		# LOGIKA DOUBLE CLICK (MASUK RUANGAN)
		if event.double_click:
			if is_open:
				masuk_ruangan()
			else:
				# Kalau pintu tertutup tapi di double click
				if sudah_jebol:
					ui_node.show_message("Buka dulu pintunya!", Color.CORAL)
				else:
					ui_node.show_message("Terhalang kayu!", Color.CORAL)
		
		# LOGIKA SINGLE CLICK (INTERAKSI)
		else:
			eksekusi_pintu_ortu(player)

func eksekusi_pintu_ortu(player):
	# KONDISI 1: Belum Jebol (Masih ada kayu)
	if not sudah_jebol:
		# Cek apakah player memilih Palu di inventory
		if ui_node.selected_item_name == item_perusak:
			hancurkan_kayu()
		elif ui_node.selected_item_name == "":
			ui_node.show_message("Pintu dipaku mati dengan kayu...", Color.CORAL)
		else:
			ui_node.show_message("Item ini tidak cukup kuat.", Color.LIGHT_GRAY)
		return

	# KONDISI 2: Sudah Jebol (Interaksi Buka/Tutup Biasa)
	if is_open:
		# Cek apakah player berdiri di tengah pintu saat mau nutup
		if player.global_position.x > door_x_min and player.global_position.x < door_x_max:
			ui_node.show_message("Pintu terhalang badanmu!", Color.CORAL)
		else:
			tutup_pintu(player)
	else:
		buka_pintu()
	
	_save_state()

func hancurkan_kayu():
	sudah_jebol = true
	
	# Hilangkan visual kayu
	if wood_sprite: wood_sprite.hide()
	
	# Opsional: Hapus Palu dari inventory jika sekali pakai
	# ui_node.remove_from_inventory(item_perusak) 
	
	ui_node.show_message("BRAKK! Kayu penghalang hancur!", Color.ORANGE_RED)
	
	# Simpan state agar kayu tidak muncul lagi pas load
	_save_state()

func masuk_ruangan():
	print("Player masuk ke kamar orang tua...")
	# Logika Pindah Scene via Global
	if scene_dalam_kamar:
		Global.next_spawn_pos = spawn_pos_kamar
		Global.is_transitioning = true
		ui_node.fade_out() # Efek gelap
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file(scene_dalam_kamar)
	else:
		ui_node.show_message("Scene kamar belum di-assign!", Color.RED)

# --- FUNGSI VISUAL BUKA/TUTUP (Sama seperti sebelumnya) ---
func buka_pintu():
	is_open = true
	sprite.region_rect = koordinat_buka
	if wall_collision: wall_collision.set_collision_layer_value(1, false)
	_set_lights_clipping(false)
	if parents_room_darkener: parents_room_darkener.hide()
	if hall_darkener: hall_darkener.hide()

func tutup_pintu(player):
	is_open = false
	sprite.region_rect = koordinat_tutup
	if wall_collision: wall_collision.set_collision_layer_value(1, true)
	_set_lights_clipping(true)
	if player.global_position.x <= door_x_min:
		if parents_room_darkener: parents_room_darkener.show()
		if hall_darkener: hall_darkener.hide()
	else:
		if parents_room_darkener: parents_room_darkener.hide()
		if hall_darkener: hall_darkener.show()

func _set_lights_clipping(enabled: bool):
	if parents_light_frame:
		parents_light_frame.clip_contents = enabled

func _save_state():
	Global.save_state(self.name, {
		"unlocked": sudah_jebol, 
		"is_open": is_open
	})
