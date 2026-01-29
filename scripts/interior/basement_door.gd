extends Area2D

@export_group("UI & Visual")
@export var ui_node: CanvasLayer
@export var sprite: Sprite2D       
@export var koordinat_buka: Rect2
@export var koordinat_tutup: Rect2 
@export var jarak_toleransi: float = 128.0

@export_group("Lock Settings")
@export var is_locked: bool = true # Default terkunci
@export var nama_kunci: String = "Kunci Basement" # Sesuaikan nama item di Inventory
@export var pesan_terkunci: String = "Terkunci. Butuh kunci khusus."

@export_group("Teleport Settings")
@export_file("*.tscn") var scene_basement 
@export var spawn_pos_basement: Vector2 = Vector2.ZERO 
@export var spawn_flip_h: bool = false # Player menghadap mana di basement?

# State
var sudah_di_unlock: bool = false 
var is_open: bool = false

func _ready():
	# 1. Load Data Save
	var saved = Global.get_state(self.name)
	if saved:
		sudah_di_unlock = saved.get("unlocked", false)
		is_open = saved.get("is_open", false)
	else:
		sudah_di_unlock = not is_locked # Ikut setting inspector kalau belum ada save
		is_open = false

	update_visual_state()
	
	# 2. Hover Cursor
	mouse_entered.connect(func():
		if sprite: sprite.modulate = Color(1.2, 1.2, 1.2)
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	)
	mouse_exited.connect(func():
		if sprite: sprite.modulate = Color(1, 1, 1)
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().current_scene.find_child("Player", true, false)
		if not player: return
		
		# Cek Jarak (Player ada di depan pintu atau tidak)
		if abs(player.global_position.x - self.global_position.x) > jarak_toleransi:
			ui_node.show_message("Terlalu jauh...", Color.LIGHT_GRAY)
			return
			
		# --- LOGIKA UTAMA ---
		
		# 1. CEK KUNCI (Kalau belum di-unlock)
		if not sudah_di_unlock:
			cek_buka_kunci()
			return 

		# 2. KALAU SUDAH UNLOCK
		
		# A. Double Click = INGIN MASUK
		if event.double_click:
			if is_open:
				masuk_basement()
			else:
				ui_node.show_message("Buka dulu pintunya.", Color.CORAL)
				
		# B. Single Click = BUKA / TUTUP
		else:
			is_open = not is_open # Switch on/off
			update_visual_state()
			_save_state()

func cek_buka_kunci():
	# Cek item yang sedang dipegang player di Inventory UI
	if ui_node.selected_item_name == nama_kunci:
		sudah_di_unlock = true
		is_open = true # Langsung buka biar feedbacknya enak
		
		# Hapus kunci (Opsional, aktifkan baris bawah kalau kunci sekali pakai)
		# ui_node.remove_from_inventory(nama_kunci)
		
		ui_node.show_message("Ceklek! Pintu terbuka.", Color.AQUAMARINE)
		update_visual_state()
		_save_state()
	
	elif ui_node.selected_item_name == "":
		ui_node.show_message(pesan_terkunci, Color.CORAL)
	
	else:
		ui_node.show_message("Kunci ini tidak cocok.", Color.CORAL)

func update_visual_state():
	# Cuma ganti gambar region. Tidak ada collision fisik yang diubah.
	if is_open:
		sprite.region_rect = koordinat_buka
	else:
		sprite.region_rect = koordinat_tutup

func masuk_basement():
	print("Player masuk ke basement...")
	if scene_basement:
		Global.next_spawn_pos = spawn_pos_basement
		Global.next_spawn_flip = spawn_flip_h
		Global.is_transitioning = true
		
		ui_node.fade_out()
		
		# Tunggu fade out sedikit
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file(scene_basement)
	else:
		ui_node.show_message("ERROR: Scene Basement belum diisi!", Color.RED)

func _save_state():
	Global.save_state(self.name, {
		"unlocked": sudah_di_unlock, 
		"is_open": is_open
	})
