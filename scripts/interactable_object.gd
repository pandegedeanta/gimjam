extends Area2D

@export var ui_node: CanvasLayer

# --- 1. MODE INTERAKSI ---
# ITEM: Laci biasa, Bed, Palu (Ambil barang)
# LETTER: Drawer khusus surat (Baca doang/baca dulu)
# SOUND_ONLY: Jam Dinding (Cuma bunyi)
# TV: Menyalakan overlay TV
enum InteractType { ITEM, LETTER, SOUND_ONLY, TV }
@export var interaction_type: InteractType = InteractType.ITEM

@export_group("Settings Objek")
@export var sprite: Sprite2D       
@export var is_standalone_item: bool = false # Centang jika benda geletak (Palu)
@export var can_close_again: bool = true     # MATIKAN centang ini untuk KASUR (Bed)
@export var is_locked: bool = false
@export var correct_code: String = "1234"
@export var interaction_dist: float = 200.0 # Tips: Naikkan jadi 350-400 untuk Kasur/Objek besar

@export_group("Data Item / Surat")
@export var nama_item: String = "Kertas"
@export_multiline var isi_surat: String = "Jangan dibaca..." # Teks untuk mode LETTER
@export var deskripsi_pesan: String = "Item berhasil diambil!"

@export_group("Visual Regions")
# Tips: Kalau malas isi region, biarkan 0,0,0,0. Script akan pakai Full Texture.
@export var region_closed: Rect2      # Laci Tutup / Ada Bantal
@export var region_open_full: Rect2   # Laci Buka isi Kertas / Bantal Hilang ada Kunci
@export var region_open_empty: Rect2  # Laci Kosong / Kasur Kosong
@export var overlay_rect: Rect2       # Gambar Item/Surat saat di-zoom

@export_group("Extras (TV & Sound)")
@export var tv_visual_root: Node2D 
@export var sound_player: AudioStreamPlayer2D # Masukkan node Audio di sini (utk Jam)

enum State { CLOSED, OPEN_FULL, OPEN_EMPTY }
var current_state = State.CLOSED
var item_taken = false

func _ready():
	input_pickable = true 
	
	# Logic Otomatis Nama (Biar gak capek rename di inspector)
	if "Drawer" in name and nama_item == "Kertas": 
		nama_item = "Kunci Kamar"
	
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
		if is_standalone_item and item_taken: return

		var player = get_tree().current_scene.find_child("Player", true, false)
		if player:
			var dist = abs(global_position.x - player.global_position.x)
			if dist <= interaction_dist:
				handle_click()
			else:
				if ui_node: ui_node.show_message("Terlalu jauh...", Color.LIGHT_GRAY)

func handle_click():
	if not ui_node: return

	# 1. SUARA (JAM)
	if sound_player:
		sound_player.play()
		if interaction_type == InteractType.SOUND_ONLY:
			# Kalau cuma jam, selesai disini. Gak perlu buka laci.
			return

	# 2. TV
	if interaction_type == InteractType.TV and tv_visual_root:
		ui_node.show_tv_overlay(tv_visual_root)
		await ui_node.overlay_closed
		return 

	# 3. INTERAKSI VISUAL (LACI / KASUR / ITEM)
	if sprite: 
		# Cek Gembok
		if is_locked and current_state == State.CLOSED:
			ui_node.show_gembok(correct_code)
			await ui_node.overlay_closed
			if ui_node.is_unlocked:
				is_locked = false
			else:
				return 

		# Logic Standalone (Palu)
		if is_standalone_item:
			if not item_taken:
				await _ambil_item_sequence()
		
		# Logic Laci / Kasur
		else:
			match current_state:
				State.CLOSED:
					# Buka
					current_state = State.OPEN_EMPTY if item_taken else State.OPEN_FULL
				
				State.OPEN_FULL:
					if interaction_type == InteractType.LETTER:
						# MODE SURAT: Baca dulu
						# Kita pakai tekstur sprite tapi dicrop sesuai overlay_rect
						var atlas = _get_safe_texture(overlay_rect)
						ui_node.show_letter(isi_surat, sprite.texture, overlay_rect)
						await ui_node.overlay_closed
						
						# Setelah baca, biasanya laci tetap terbuka, atau tutup otomatis?
						# Kita biarkan terbuka biar player klik lagi buat tutup
					
					else:
						# MODE ITEM: Ambil Barang
						if not item_taken:
							await _ambil_item_sequence()
						else:
							current_state = State.OPEN_EMPTY
				
				State.OPEN_EMPTY:
					# Logic Tutup Kembali
					if can_close_again:
						current_state = State.CLOSED
					else:
						# KHUSUS BED: Bantal yang dibuang gak bisa balik
						ui_node.show_message("Tidak perlu menutupnya lagi.", Color.LIGHT_GRAY)

		update_visual()
		Global.save_state(self.name, {"state": current_state, "taken": item_taken, "is_locked": is_locked})

func _ambil_item_sequence():
	# Menampilkan item overlay
	var atlas = _get_safe_texture(overlay_rect)
	ui_node.show_item(atlas)
	
	await ui_node.overlay_closed
	
	ui_node.add_to_inventory(nama_item, sprite.texture, atlas.region)
	ui_node.show_message(deskripsi_pesan, Color.AQUAMARINE)
	
	item_taken = true
	current_state = State.OPEN_EMPTY

func update_visual():
	if not sprite: return
	
	if is_standalone_item and item_taken:
		sprite.hide()
		$CollisionShape2D.set_deferred("disabled", true)
		return
	
	sprite.show()
	$CollisionShape2D.set_deferred("disabled", false)
	
	# Tentukan rect mana yang dipakai
	var target_rect = Rect2()
	match current_state:
		State.CLOSED: target_rect = region_closed
		State.OPEN_FULL: target_rect = region_open_full
		State.OPEN_EMPTY: target_rect = region_open_empty
	
	# PENGAMAN: Kalau User Lupa Isi Region (0,0,0,0), Matikan Region Enabled
	# Biar gambar utuh muncul (Gak ilang)
	if target_rect.has_area():
		sprite.region_enabled = true
		sprite.region_rect = target_rect
	else:
		# Jika region 0,0,0,0 -> Pakai gambar full (atau biarkan settingan awal)
		# Ini mencegah sprite menghilang tiba-tiba
		pass 

# Helper: Biar gak error kalau rect kosong
func _get_safe_texture(rect: Rect2) -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.atlas = sprite.texture
	if rect.has_area():
		atlas.region = rect
	else:
		# Fallback ke full texture
		atlas.region = Rect2(Vector2.ZERO, sprite.texture.get_size())
	return atlas
