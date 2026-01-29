extends Area2D

@export_group("UI & Visual")
@export var ui_node: CanvasLayer
@export var sprite: Sprite2D       
@export var wood_sprite: Sprite2D  
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
@export_file("*.tscn") var scene_dalam_kamar 
@export var spawn_pos_kamar: Vector2 = Vector2.ZERO 

var sudah_jebol: bool = false 
var is_open: bool = false

func _ready():
	# 1. Cek progres dari Global
	var saved = Global.get_state(self.name)
	if saved:
		sudah_jebol = saved.get("unlocked", false)
		if wood_sprite: wood_sprite.visible = not sudah_jebol
		
		is_open = saved.get("is_open", false)
		if is_open:
			sprite.region_rect = koordinat_buka
			if wall_collision: wall_collision.set_collision_layer_value(1, false)
			_set_lights_clipping(false)
	else:
		if wood_sprite: wood_sprite.visible = true

	# 2. Setup Collision Awal
	if wall_collision and not is_open: 
		wall_collision.set_collision_layer_value(1, true)
	
	_set_lights_clipping(not is_open)
	
	# 3. Hover Signal
	mouse_entered.connect(_on_mouse_enter)
	mouse_exited.connect(_on_mouse_exit)

func _on_mouse_enter():
	if sprite: sprite.modulate = Color(1.2, 1.2, 1.2)
	if wood_sprite and wood_sprite.visible: wood_sprite.modulate = Color(1.2, 1.2, 1.2)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exit():
	if sprite: sprite.modulate = Color(1, 1, 1)
	if wood_sprite: wood_sprite.modulate = Color(1, 1, 1)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

# --- LOGIKA KLIK UTAMA ---
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().current_scene.find_child("Player", true, false)
		if not player: return
		
		if abs(player.global_position.x - self.global_position.x) > jarak_toleransi:
			ui_node.show_message("Terlalu jauh...", Color.LIGHT_GRAY)
			return
			
		# --- CEK 1: APAKAH MASIH DIPAKU KAYU? ---
		if not sudah_jebol:
			# Kalau di-Double Click pas masih dipaku
			if event.double_click:
				ui_node.show_message("Hancurkan dulu kayunya!", Color.CORAL)
			# Kalau Single Click -> Cek Palu
			else:
				cek_hancurkan_kayu()
			return 

		# --- CEK 2: SUDAH JEBOL (Pintu Normal) ---
		
		# A. LOGIKA DOUBLE CLICK = MASUK
		if event.double_click:
			if is_open:
				masuk_ruangan()
			else:
				# Kalau tertutup tapi buru-buru double click -> Otomatis Buka lalu Masuk (Opsional)
				# Atau suruh buka dulu:
				ui_node.show_message("Buka dulu pintunya.", Color.CORAL)
				
		# B. LOGIKA SINGLE CLICK = BUKA / TUTUP
		else:
			if is_open:
				# Kalau terbuka -> Tutup
				if player.global_position.x > door_x_min and player.global_position.x < door_x_max:
					ui_node.show_message("Minggir dulu, terhalang badan.", Color.CORAL)
				else:
					tutup_pintu(player)
					# ui_node.show_message("Pintu Ditutup.", Color.WHITE) # Optional
			else:
				# Kalau tertutup -> Buka
				buka_pintu()
				# ui_node.show_message("Pintu Terbuka.", Color.WHITE) # Optional
			
			_save_state()

# --- HELPER FUNCTIONS ---

func cek_hancurkan_kayu():
	if ui_node.selected_item_name == item_perusak:
		hancurkan_kayu()
	elif ui_node.selected_item_name == "":
		ui_node.show_message("Pintu dipaku mati...", Color.CORAL)
	else:
		ui_node.show_message("Item ini tidak mempan.", Color.LIGHT_GRAY)

func hancurkan_kayu():
	sudah_jebol = true
	if wood_sprite: wood_sprite.hide()
	
	# Hapus Palu (Karena is_standalone_item di palu logic-nya 'hide' doang, 
	# kita bisa hapus dari inventory UI biar logis palunya 'dipakai')
	# ui_node.remove_from_inventory(item_perusak) 
	
	ui_node.show_message("BRAKK! Kayu hancur!", Color.ORANGE_RED)
	_save_state()

func masuk_ruangan():
	print("Player masuk ke kamar orang tua...")
	if scene_dalam_kamar:
		Global.next_spawn_pos = spawn_pos_kamar
		Global.is_transitioning = true
		ui_node.fade_out()
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file(scene_dalam_kamar)
	else:
		ui_node.show_message("Scene tujuan belum di-set!", Color.RED)

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
