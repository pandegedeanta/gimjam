extends Area2D

@export var ui_node: CanvasLayer

enum InteractType { ITEM, LETTER, SOUND_ONLY, TV }
@export var interaction_type: InteractType = InteractType.ITEM

@export_group("Settings Objek")
@export var sprite: Sprite2D       
@export var is_standalone_item: bool = false 
@export var can_close_again: bool = true     
@export var is_locked: bool = false
@export var correct_code: String = "1234"
@export var interaction_dist: float = 200.0 

@export_group("Data Item / Surat")
@export var nama_item: String = "Kertas"
@export_multiline var isi_surat: String = "Jangan dibaca..." 
@export var deskripsi_pesan: String = "Item diambil"

@export_group("Visual Regions")
@export var region_closed: Rect2      
@export var region_open_full: Rect2   
@export var region_open_empty: Rect2  
@export var overlay_rect: Rect2       

@export_group("Extras (TV & Sound)")
@export var tv_visual_root: Node2D 
@export var sound_player: AudioStreamPlayer2D 

enum State { CLOSED, OPEN_FULL, OPEN_EMPTY }
var current_state = State.CLOSED
var item_taken = false

func _ready():
	input_pickable = true 
	
	if "Drawer" in name and nama_item == "Kertas": 
		nama_item = "Kunci Kamar"
	
	var saved = Global.get_state(self.name)
	if saved:
		current_state = saved.get("state", State.CLOSED)
		item_taken = saved.get("taken", false)
		is_locked = saved.get("is_locked", is_locked)
	
	update_visual()
	
	mouse_entered.connect(func(): 
		if ui_node and ui_node.has_method("is_blocking_input") and ui_node.is_blocking_input(): return
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
		if ui_node and ui_node.has_method("is_blocking_input") and ui_node.is_blocking_input(): return
		if is_standalone_item and item_taken: return

		var player = get_tree().current_scene.find_child("Player", true, false)
		if player:
			var dist = abs(global_position.x - player.global_position.x)
			if dist <= interaction_dist:
				handle_click()
			else:
				if ui_node: ui_node.show_message("Terlalu jauh...", Color.WHITE)

func handle_click():
	if not ui_node: return

	# SUARA
	if sound_player:
		sound_player.play()
		if interaction_type == InteractType.SOUND_ONLY:
			return

	# TV
	if interaction_type == InteractType.TV and tv_visual_root:
		ui_node.show_tv_overlay(tv_visual_root)
		return 

	# INTERAKSI VISUAL
	if sprite: 
		# [PERBAIKAN ARGUMEN DI SINI]
		if is_locked and current_state == State.CLOSED:
			ui_node.show_gembok(self, correct_code)
			return 

		# Logic Palu
		if is_standalone_item:
			if not item_taken:
				await _ambil_item_sequence()
		
		# Logic Laci / Kasur
		else:
			match current_state:
				State.CLOSED:
					current_state = State.OPEN_EMPTY if item_taken else State.OPEN_FULL
					ui_node.show_message("Terbuka", Color.WHITE) 
				
				State.OPEN_FULL:
					if interaction_type == InteractType.LETTER:
						var atlas = _get_safe_texture(overlay_rect)
						ui_node.show_letter(isi_surat, sprite.texture, atlas.region)
					else:
						if not item_taken:
							await _ambil_item_sequence()
						else:
							current_state = State.OPEN_EMPTY
				
				State.OPEN_EMPTY:
					if can_close_again:
						current_state = State.CLOSED
					else:
						ui_node.show_message("Kosong", Color.WHITE)

		update_visual()
		Global.save_state(self.name, {"state": current_state, "taken": item_taken, "is_locked": is_locked})

# FUNGSI CALLBACK dari UI
func on_unlock_success():
	print("Laci Unlocked!")
	is_locked = false
	
	if item_taken:
		current_state = State.OPEN_EMPTY
	else:
		current_state = State.OPEN_FULL
	
	update_visual()
	Global.save_state(self.name, {"state": current_state, "taken": item_taken, "is_locked": is_locked})

func _ambil_item_sequence():
	var atlas = _get_safe_texture(overlay_rect)
	ui_node.show_item(atlas)
	
	await ui_node.overlay_closed
	
	ui_node.add_to_inventory(nama_item, sprite.texture, atlas.region)
	ui_node.show_message(deskripsi_pesan, Color.WHITE)
	
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
	
	var target_rect = Rect2()
	match current_state:
		State.CLOSED: target_rect = region_closed
		State.OPEN_FULL: target_rect = region_open_full
		State.OPEN_EMPTY: target_rect = region_open_empty
	
	if target_rect.has_area():
		sprite.region_enabled = true
		sprite.region_rect = target_rect
	else:
		if sprite.region_enabled and target_rect.size == Vector2.ZERO:
			sprite.region_enabled = false

func _get_safe_texture(rect: Rect2) -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.atlas = sprite.texture
	if rect.has_area():
		atlas.region = rect
	else:
		atlas.region = Rect2(Vector2.ZERO, sprite.texture.get_size())
	return atlas
