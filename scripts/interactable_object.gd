extends Area2D

@export var ui_node: CanvasLayer

# --- MODIFIKASI: TV & LACI DALAM SATU SCRIPT ---
@export_group("TV Settings (Khusus TV)")
@export var tv_visual_root: Node2D 

@export_group("Item Settings")
@export var sprite: Sprite2D       
@export var is_standalone_item: bool = false # Centang ini buat PALU/ITEM LEPAS
@export var is_locked: bool = false
@export var correct_code: String = "1234"
@export var interaction_dist: float = 200.0 
@export var nama_item: String = "Kertas"
@export var deskripsi_pesan: String = "Item berhasil diambil!"

@export_group("Regions (Khusus Laci)")
@export var region_closed: Rect2
@export var region_open_full: Rect2
@export var region_open_empty: Rect2
@export var overlay_rect: Rect2

enum State { CLOSED, OPEN_FULL, OPEN_EMPTY }
var current_state = State.CLOSED
var item_taken = false

func _ready():
	input_pickable = true 
	
	# Muat progres dari Global
	var saved = Global.get_state(self.name)
	if saved:
		current_state = saved.get("state", State.CLOSED)
		item_taken = saved.get("taken", false)
		is_locked = saved.get("is_locked", is_locked)
	
	update_visual()
	
	# Hover visual
	mouse_entered.connect(func(): 
		if sprite and sprite.visible: sprite.modulate = Color(1.2, 1.2, 1.2)
		if tv_visual_root: tv_visual_root.modulate = Color(1.2, 1.2, 1.2)
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	)
	mouse_exited.connect(func(): 
		if sprite: sprite.modulate = Color(1, 1, 1)
		if tv_visual_root: tv_visual_root.modulate = Color(1, 1, 1)
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Kalau item lepas sudah diambil, jangan respon klik lagi
		if is_standalone_item and item_taken:
			return

		var player = get_tree().current_scene.find_child("Player", true, false)
		if player:
			var dist = abs(global_position.x - player.global_position.x)
			if dist <= interaction_dist:
				handle_click()
			else:
				if ui_node: ui_node.show_message("Terlalu jauh...", Color.LIGHT_GRAY)

func handle_click():
	if not ui_node:
		push_error("UI Node belum di-assign di Inspector!")
		return

	# --- JALUR 1: TV ---
	if tv_visual_root:
		ui_node.show_tv_overlay(tv_visual_root)
		await ui_node.overlay_closed
		return 

	# --- JALUR 2: LACI / ITEM ---
	if sprite: 
		# A. CEK GEMBOK DULU (Berlaku buat Laci maupun Item terkunci)
		if is_locked and current_state == State.CLOSED:
			ui_node.show_gembok(correct_code)
			await ui_node.overlay_closed
			if ui_node.is_unlocked:
				is_locked = false
				# Setelah unlock, lanjut ke bawah untuk membuka/mengambil
			else:
				return # Masih terkunci, stop di sini.

		# B. LOGIKA PISAH (1x KLIK vs 2x KLIK)
		if is_standalone_item:
			# --- LOGIKA BENDA LEPAS (1x KLIK LANGSUNG AMBIL) ---
			if not item_taken:
				await _ambil_item_sequence()
			else:
				pass # Sudah diambil, do nothing
		
		else:
			# --- LOGIKA LACI (2x KLIK: BUKA DULU -> BARU AMBIL) ---
			match current_state:
				State.CLOSED:
					# Klik 1: Cuma buka visual laci
					current_state = State.OPEN_EMPTY if item_taken else State.OPEN_FULL
				
				State.OPEN_FULL:
					# Klik 2: Kalau ada isi, ambil. Kalau kosong, biarin.
					if not item_taken:
						await _ambil_item_sequence()
					else:
						current_state = State.OPEN_EMPTY
				
				State.OPEN_EMPTY:
					# Klik 3: Tutup laci
					current_state = State.CLOSED

		update_visual()
		Global.save_state(self.name, {"state": current_state, "taken": item_taken, "is_locked": is_locked})
	
	else:
		print("ERROR CONFIG: Objek ", self.name, " belum di-setting di Inspector!")

# --- HELPER FUNCTION: PROSES AMBIL BARANG ---
func _ambil_item_sequence():
	var atlas = AtlasTexture.new()
	atlas.atlas = sprite.texture
	atlas.region = overlay_rect
	ui_node.show_item(atlas)
	
	await ui_node.overlay_closed
	
	ui_node.add_to_inventory(nama_item, sprite.texture, overlay_rect)
	ui_node.show_message(deskripsi_pesan, Color.AQUAMARINE)
	
	item_taken = true
	current_state = State.OPEN_EMPTY

func update_visual():
	if not sprite: return
	
	# HILANGKAN VISUAL JIKA BENDA LEPAS SUDAH DIAMBIL
	if is_standalone_item and item_taken:
		sprite.hide()
		var coll = get_node_or_null("CollisionShape2D")
		if coll: coll.set_deferred("disabled", true)
		return
	
	# VISUAL STANDAR
	sprite.show()
	var coll = get_node_or_null("CollisionShape2D")
	if coll: coll.set_deferred("disabled", false)
	
	match current_state:
		State.CLOSED: sprite.region_rect = region_closed
		State.OPEN_FULL: sprite.region_rect = region_open_full
		State.OPEN_EMPTY: sprite.region_rect = region_open_empty
