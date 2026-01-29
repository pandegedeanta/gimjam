extends CanvasLayer

signal code_correct
signal overlay_closed

# --- REFERENSI UI UMUM ---
@onready var game_message = $GameMessage
@onready var static_hint = $StaticHint
@onready var dimmer = $Dimmer
@onready var layer_overlay = $Layer_Overlay
@onready var inventory_bar = $InventoryBar
@onready var screen_fade = $ScreenFade 

# --- REFERENSI GEMBOK (TUMBLER) ---
@onready var code_input_tumbler = $Layer_Overlay/CodeInput 
@onready var texture_rect = $Layer_Overlay/CodeInput/TextureRect
@onready var hbox = $Layer_Overlay/CodeInput/TextureRect/HBoxContainer

# --- REFERENSI ITEM DISPLAY & TV ---
@onready var item_display = $Layer_Overlay/ItemDisplay
@onready var tv_container = $Layer_Overlay/TVContainer
@onready var tv_viewport = $Layer_Overlay/TVContainer/SubViewport

# --- REFERENSI BRANKAS (CODE PANEL) ---
@onready var safe_panel = $Layer_Overlay/CodePanel
@onready var safe_display = $Layer_Overlay/CodePanel/Display
@onready var safe_keypad = $Layer_Overlay/CodePanel/Keypad
@onready var back_button = $Layer_Overlay/CodePanel/BackButton

@export_group("Gembok Regions")
@export var region_tutup: Rect2 
@export var region_buka: Rect2

@export_group("Grid Dial Settings (5x2)")
@export var frame_width: float = 372.0   
@export var frame_height: float = 1024.0 
@export var columns: int = 5              

# Variable Internal
var current_dial_values: Array[int] = [0, 0, 0, 0] 
var target_code_array: Array[int] = [1, 2, 3, 4]
var is_unlocked: bool = false
var message_tween: Tween 
var inventory_items = [] 
var selected_item_name: String = ""
var last_selected_slot: TextureButton = null

# Variable Brankas
var current_safe_code: String = ""
var target_safe_code: String = ""
var active_safe_object = null
var active_gembok_object = null # Simpan referensi laci

func _ready():
	if not get_node_or_null("/root/Global"):
		push_error("Global.gd belum dipasang di Autoload!")
		return

	# --- SETUP MOUSE FILTER ---
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	layer_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_display.mouse_filter = Control.MOUSE_FILTER_STOP 
	
	if code_input_tumbler:
		code_input_tumbler.mouse_filter = Control.MOUSE_FILTER_STOP
		code_input_tumbler.hide()
	
	if safe_panel:
		safe_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		safe_panel.hide()
	
	if screen_fade:
		screen_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE

	hide_all_overlays_init()
	inventory_bar.show()
	
	if screen_fade:
		screen_fade.self_modulate.a = 1.0
		fade_in(1.0) 
	
	setup_dial_system()     
	setup_safe_keypad()     
	
	await get_tree().create_timer(0.1).timeout
	_reload_inventory()

# [DITAMBAHKAN KEMBALI AGAR TIDAK ERROR]
func is_blocking_input() -> bool:
	return dimmer.visible

func lock_player_movement(locked: bool):
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("set_input_locked"):
		player.set_input_locked(locked)

func hide_all_overlays_init():
	dimmer.hide()
	layer_overlay.hide()
	tv_container.hide() 
	
	if safe_panel: safe_panel.hide()
	if code_input_tumbler: code_input_tumbler.hide()
	item_display.hide()
	
	static_hint.modulate.a = 0
	game_message.modulate.a = 0
	lock_player_movement(false) 

# ==========================================================
# 🔥 LOGIKA BRANKAS (CODE PANEL) 🔥
# ==========================================================

func setup_safe_keypad():
	if not safe_keypad: return

	for btn in safe_keypad.get_children():
		if btn is BaseButton:
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			
		if btn.name.begins_with("Btn"):
			var char_code = btn.name.substr(3, 1) 
			if char_code.is_valid_int():
				if not btn.pressed.is_connected(_on_keypad_digit):
					btn.pressed.connect(_on_keypad_digit.bind(char_code))
			elif char_code == "C":
				if not btn.pressed.is_connected(_on_keypad_clear):
					btn.pressed.connect(_on_keypad_clear)
			elif char_code == "E":
				if not btn.pressed.is_connected(_on_keypad_enter):
					btn.pressed.connect(_on_keypad_enter)
	
	if back_button:
		back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if not back_button.pressed.is_connected(_on_safe_close_pressed):
			back_button.pressed.connect(_on_safe_close_pressed)

func show_safe_panel(safe_obj, correct_code: String):
	if not safe_panel: return

	active_safe_object = safe_obj
	target_safe_code = correct_code
	current_safe_code = ""
	
	lock_player_movement(true)
	inventory_bar.hide()
	dimmer.show()
	layer_overlay.show()
	
	if code_input_tumbler: code_input_tumbler.hide()
	item_display.hide()
	tv_container.hide()
	
	safe_panel.show()
	update_safe_display()
	static_hint.modulate.a = 0

func _on_keypad_digit(digit: String):
	if current_safe_code.length() < 6: 
		current_safe_code += digit
		update_safe_display()

func _on_keypad_clear():
	current_safe_code = ""
	update_safe_display()

func _on_keypad_enter():
	if current_safe_code == target_safe_code:
		show_message("Sandi Diterima", Color.WHITE)
		if active_safe_object and active_safe_object.has_method("open"):
			active_safe_object.open()
		
		await get_tree().create_timer(0.8).timeout
		hide_all()
		overlay_closed.emit()
	else:
		show_message("Sandi Salah", Color.WHITE)
		current_safe_code = ""
		update_safe_display()

func _on_safe_close_pressed():
	hide_all()
	overlay_closed.emit()

func update_safe_display():
	if safe_display:
		safe_display.text = current_safe_code

# ==========================================================
# 📺 LOGIKA TV & OVERLAYS LAIN
# ==========================================================

func show_tv_overlay(original_tv_node: Node2D):
	lock_player_movement(true)
	inventory_bar.hide()
	dimmer.show()
	layer_overlay.show()
	
	if code_input_tumbler: code_input_tumbler.hide()
	if safe_panel: safe_panel.hide()
	item_display.hide()
	
	for child in tv_viewport.get_children():
		child.queue_free()
	
	tv_container.show()
	
	var tv_copy = original_tv_node.duplicate()
	tv_copy.process_mode = Node.PROCESS_MODE_ALWAYS 
	tv_viewport.add_child(tv_copy)
	tv_copy.position = tv_viewport.size / 2
	tv_copy.scale = Vector2(1.0, 1.0) 
	
	var anim_in_copy = tv_copy.get_node_or_null("AnimatedSprite2D")
	if anim_in_copy: anim_in_copy.play()
	
	static_hint.modulate.a = 0 

# ==========================================================
# 🔒 LOGIKA GEMBOK (DIAL) - [PERBAIKAN ATLAS]
# ==========================================================

func setup_dial_system():
	if not hbox: return
	for i in range(hbox.get_child_count()):
		var vbox = hbox.get_child(i)
		var display = vbox.get_node("TextureRect")
		
		# --- PERBAIKAN: PAKSA JADI ATLAS TEXTURE ---
		# Jika texturenya masih gambar biasa (StreamTexture), kita ubah jadi Atlas
		if display.texture and not (display.texture is AtlasTexture):
			var new_atlas = AtlasTexture.new()
			new_atlas.atlas = display.texture
			new_atlas.region = Rect2(0, 0, frame_width, frame_height)
			display.texture = new_atlas
		# Jika sudah Atlas, kita duplikat agar unik per digit
		elif display.texture is AtlasTexture:
			display.texture = display.texture.duplicate()
			display.texture.region.size = Vector2(frame_width, frame_height)
		
		# Setup Tombol
		vbox.get_node("BtnUp").pressed.connect(_on_dial_changed.bind(i, 1))
		vbox.get_node("BtnDown").pressed.connect(_on_dial_changed.bind(i, -1))
		
		vbox.get_node("BtnUp").mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		vbox.get_node("BtnDown").mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _on_dial_changed(digit_index: int, delta: int):
	if is_unlocked: return
	current_dial_values[digit_index] = clampi(current_dial_values[digit_index] + delta, 0, 9)
	
	var val = current_dial_values[digit_index]
	var col = val % columns            
	var row = int(val / columns)       
	var display = hbox.get_child(digit_index).get_node("TextureRect")
	
	# Pastikan texturenya Atlas sebelum akses region
	if display.texture is AtlasTexture:
		display.texture.region.position.x = col * frame_width
		display.texture.region.position.y = row * frame_height
	
	check_combination()

func check_combination():
	if current_dial_values == target_code_array:
		is_unlocked = true
		texture_rect.texture.region = region_buka
		show_message("Terbuka", Color.WHITE)
		
		if active_gembok_object and active_gembok_object.has_method("on_unlock_success"):
			active_gembok_object.on_unlock_success()
			
		await get_tree().create_timer(0.5).timeout
		code_correct.emit()
		hide_all()
		overlay_closed.emit()

func show_gembok(obj, correct_code_str: String):
	active_gembok_object = obj
	
	lock_player_movement(true)
	inventory_bar.hide()
	is_unlocked = false
	target_code_array.clear()
	
	for i in range(correct_code_str.length()):
		target_code_array.append(int(correct_code_str[i]))
		
	current_dial_values = [0, 0, 0, 0]
	
	# Reset visual ke 0
	for i in range(hbox.get_child_count()):
		var display = hbox.get_child(i).get_node("TextureRect")
		if display.texture is AtlasTexture:
			display.texture.region.position = Vector2(0, 0)
		
	texture_rect.texture.region = region_tutup
	dimmer.show()
	layer_overlay.show()
	
	if code_input_tumbler: code_input_tumbler.show()
	if safe_panel: safe_panel.hide()
	item_display.hide()
	tv_container.hide() 

# ==========================================================
# 📄 LOGIKA ITEM & SURAT
# ==========================================================

func show_item(tex: Texture):
	lock_player_movement(true)
	inventory_bar.hide()
	dimmer.show()
	layer_overlay.show()
	
	if code_input_tumbler: code_input_tumbler.hide()
	if safe_panel: safe_panel.hide()
	tv_container.hide()
	
	item_display.texture = tex
	item_display.show()

func show_letter(text: String, tex: Texture, region: Rect2):
	lock_player_movement(true)
	inventory_bar.hide()
	dimmer.show()
	layer_overlay.show()
	
	if code_input_tumbler: code_input_tumbler.hide()
	if safe_panel: safe_panel.hide()
	tv_container.hide()

	var atlas = AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = region
	item_display.texture = atlas
	item_display.show()

	game_message.text = text
	game_message.modulate = Color.WHITE
	game_message.modulate.a = 1.0

# ==========================================================
# ⚙️ UTILS & INPUT
# ==========================================================

func show_hint(text: String):
	if static_hint:
		static_hint.text = text
		var tween = create_tween()
		tween.tween_property(static_hint, "modulate:a", 1.0, 0.2)

func hide_hint():
	if static_hint:
		var tween = create_tween()
		tween.tween_property(static_hint, "modulate:a", 0.0, 0.2)

func show_exit_hint():
	show_hint("Tekan Enter untuk keluar")

func hide_exit_hint():
	hide_hint()

func show_message(txt: String, color: Color = Color.WHITE):
	if message_tween: message_tween.kill() 
	game_message.text = txt
	game_message.modulate = color
	game_message.modulate.a = 0
	message_tween = create_tween()
	message_tween.tween_property(game_message, "modulate:a", 1.0, 0.3)
	message_tween.tween_interval(1.5)
	message_tween.tween_property(game_message, "modulate:a", 0.0, 0.3)

func fade_in(delay: float = 0.0):
	var tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_property(screen_fade, "self_modulate:a", 0.0, 0.5)

func fade_out():
	var tween = create_tween()
	tween.tween_property(screen_fade, "self_modulate:a", 1.0, 0.5)
	return tween

func _input(event):
	if not dimmer.visible: return
	if safe_panel and safe_panel.visible: return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_unlocked or item_display.visible or tv_container.visible:
			hide_all()
			overlay_closed.emit()
		elif code_input_tumbler and code_input_tumbler.visible:
			var mouse_pos = get_viewport().get_mouse_position()
			var code_rect = texture_rect.get_global_rect()
			if not code_rect.has_point(mouse_pos):
				hide_all()
				overlay_closed.emit()

func hide_all():
	dimmer.hide()
	layer_overlay.hide()
	static_hint.modulate.a = 0
	
	tv_container.hide()
	if safe_panel: safe_panel.hide()
	if code_input_tumbler: code_input_tumbler.hide()
	item_display.hide()
	
	for child in tv_viewport.get_children():
		child.queue_free()
	
	game_message.text = ""
	game_message.modulate.a = 0
	
	inventory_bar.show() 
	lock_player_movement(false) 

func _on_dimmer_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if safe_panel and safe_panel.visible: return
		hide_all()
		overlay_closed.emit()

func _on_item_display_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_all()
		overlay_closed.emit()

# --- FUNGSI INVENTORY ---
func _reload_inventory():
	await get_tree().physics_frame
	for child in inventory_bar.get_children():
		child.queue_free()
	inventory_items.clear()
	for item in Global.inventory_data:
		_create_slot_visual(item["name"], item["texture"], item["region"])
		
func add_to_inventory(item_name: String, item_tex: Texture, item_region: Rect2):
	if item_name in inventory_items: return
	var data = {"name": item_name, "texture": item_tex, "region": item_region}
	Global.add_item(data)
	_create_slot_visual(item_name, item_tex, item_region)
	
func _create_slot_visual(item_name: String, item_tex: Texture, item_region: Rect2):
	if item_name in inventory_items: return
	var slot = TextureButton.new()
	slot.name = item_name
	slot.custom_minimum_size = Vector2(64, 64) 
	slot.ignore_texture_size = true
	slot.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var border = ReferenceRect.new()
	border.name = "Border"
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.border_color = Color.YELLOW
	border.border_width = 3.0
	border.editor_only = false 
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.hide() 
	slot.add_child(border)
	var atlas = AtlasTexture.new()
	atlas.atlas = item_tex
	atlas.region = item_region
	slot.texture_normal = atlas
	slot.pressed.connect(_on_inventory_slot_pressed.bind(item_name, slot))
	inventory_bar.add_child(slot)
	inventory_items.append(item_name)

func _on_inventory_slot_pressed(item_name: String, slot: TextureButton):
	if selected_item_name == item_name:
		deselect_item()
		show_message("Tangan kosong")
	else:
		select_item(item_name, slot)
		show_message(item_name)

func select_item(item_name: String, slot: TextureButton):
	deselect_item()
	selected_item_name = item_name
	last_selected_slot = slot
	if slot.has_node("Border"):
		slot.get_node("Border").show()

func deselect_item():
	if last_selected_slot and is_instance_valid(last_selected_slot):
		if last_selected_slot.has_node("Border"):
			last_selected_slot.get_node("Border").hide()
	selected_item_name = ""
	last_selected_slot = null

func remove_from_inventory(item_name: String):
	if item_name == selected_item_name:
		deselect_item()
	if item_name in inventory_items:
		var slot = inventory_bar.get_node_or_null(item_name)
		if slot: slot.queue_free()
		inventory_items.erase(item_name)
		Global.remove_item(item_name)
