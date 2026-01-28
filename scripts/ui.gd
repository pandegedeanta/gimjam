extends CanvasLayer

signal code_correct
signal overlay_closed

@onready var game_message = $GameMessage
@onready var static_hint = $StaticHint
@onready var dimmer = $Dimmer
@onready var layer_overlay = $Layer_Overlay
@onready var texture_rect = $Layer_Overlay/CodeInput/TextureRect
@onready var hbox = $Layer_Overlay/CodeInput/TextureRect/HBoxContainer
@onready var item_display = $Layer_Overlay/ItemDisplay
@onready var inventory_bar = $InventoryBar
@onready var screen_fade = $ScreenFade 

@export_group("Gembok Regions")
@export var region_tutup: Rect2 
@export var region_buka: Rect2

@export_group("Grid Dial Settings (5x2)")
@export var frame_width: float = 372.0   
@export var frame_height: float = 1024.0 
@export var columns: int = 5              

var current_dial_values: Array[int] = [0, 0, 0, 0] 
var target_code_array: Array[int] = [1, 2, 3, 4]
var is_unlocked: bool = false
var message_tween: Tween 
var inventory_items = [] 

var selected_item_name: String = ""
var last_selected_slot: TextureButton = null

func _ready():
	# Cek apakah Global beneran ada
	if not get_node_or_null("/root/Global"):
		push_error("Woi Pande! Global.gd belum dipasang di Autoload!")
		return

	dimmer.hide()
	layer_overlay.hide()
	static_hint.modulate.a = 0
	game_message.modulate.a = 0
	
	if screen_fade:
		screen_fade.self_modulate.a = 1.0
		fade_in(1.0) 
	
	setup_dial_system()
	
	# Tunggu sebentar sebelum muat inventory (biar Global stabil)
	await get_tree().create_timer(0.1).timeout
	_reload_inventory()
	
func _reload_inventory():
	# Tunggu satu frame physics agar semua node anak (InventoryBar) sudah matang
	await get_tree().physics_frame
	
	for child in inventory_bar.get_children():
		child.queue_free()
	inventory_items.clear()
	
	print("UI: Mengecek isi tas di Global... Isi: ", Global.inventory_data.size())
	
	for item in Global.inventory_data:
		_create_slot_visual(item["name"], item["texture"], item["region"])
		
func add_to_inventory(item_name: String, item_tex: Texture, item_region: Rect2):
	# Cek apakah sudah ada di visual lokal
	if item_name in inventory_items: 
		return
	
	# Simpan ke Global (Database) jika belum ada
	var data = {"name": item_name, "texture": item_tex, "region": item_region}
	Global.add_item(data)
	
	# Gambar visualnya
	_create_slot_visual(item_name, item_tex, item_region)
	print("UI: Visual Berhasil Dibuat untuk ", item_name)
	
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

# --- SISTEM TRANSISI ---
func fade_in(delay: float = 0.0):
	var tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_property(screen_fade, "self_modulate:a", 0.0, 0.5)

func fade_out():
	var tween = create_tween()
	tween.tween_property(screen_fade, "self_modulate:a", 1.0, 0.5)
	return tween

# --- LOGIKA KLIK & HAPUS INVENTORY ---
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

# Ganti fungsi remove_from_inventory di ui.gd dengan ini:
func remove_from_inventory(item_name: String):
	if item_name == selected_item_name:
		deselect_item()
	
	if item_name in inventory_items:
		# 1. Hapus Visual
		var slot = inventory_bar.get_node_or_null(item_name)
		if slot: slot.queue_free()
		inventory_items.erase(item_name)
		
		# 2. Hapus Database (PERBAIKAN DI SINI)
		# Jangan pakai if "Global" in root, itu bikin kodenya ga jalan!
		# Langsung tembak saja karena Global sudah pasti ada (Autoload).
		Global.remove_item(item_name) 
		print("UI: Perintah hapus ", item_name, " dikirim ke Global.")
		
# --- SISTEM GEMBOK ---
func setup_dial_system():
	if not hbox: return
	for i in range(hbox.get_child_count()):
		var vbox = hbox.get_child(i)
		var display = vbox.get_node("TextureRect")
		if display.texture is AtlasTexture:
			display.texture = display.texture.duplicate()
			display.texture.region.size = Vector2(frame_width, frame_height)
		vbox.get_node("BtnUp").pressed.connect(_on_dial_changed.bind(i, 1))
		vbox.get_node("BtnDown").pressed.connect(_on_dial_changed.bind(i, -1))
		setup_ui_interaction(vbox.get_node("BtnUp"))
		setup_ui_interaction(vbox.get_node("BtnDown"))

func setup_ui_interaction(node: Control):
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.mouse_entered.connect(func(): node.self_modulate = Color(1.2, 1.2, 1.2))
	node.mouse_exited.connect(func(): node.self_modulate = Color(1, 1, 1))

func _on_dial_changed(digit_index: int, delta: int):
	if is_unlocked: return
	current_dial_values[digit_index] = clampi(current_dial_values[digit_index] + delta, 0, 9)
	var val = current_dial_values[digit_index]
	var col = val % columns          
	var row = int(val / columns)      
	var display = hbox.get_child(digit_index).get_node("TextureRect")
	display.texture.region.position.x = col * frame_width
	display.texture.region.position.y = row * frame_height
	check_combination()

func check_combination():
	if current_dial_values == target_code_array:
		is_unlocked = true
		texture_rect.texture.region = region_buka
		show_message("Gembok Terbuka!", Color.GREEN_YELLOW)
		static_hint.modulate.a = 1.0
		code_correct.emit()

func show_gembok(correct_code_str: String):
	get_tree().paused = true
	is_unlocked = false
	target_code_array.clear()
	for i in range(correct_code_str.length()):
		target_code_array.append(int(correct_code_str[i]))
	current_dial_values = [0, 0, 0, 0]
	for i in range(hbox.get_child_count()):
		var display = hbox.get_child(i).get_node("TextureRect")
		display.texture.region.position = Vector2(0, 0)
	texture_rect.texture.region = region_tutup
	dimmer.show()
	layer_overlay.show()
	$Layer_Overlay/CodeInput.show()
	item_display.hide()

func show_item(tex: Texture):
	dimmer.show()
	layer_overlay.show()
	$Layer_Overlay/CodeInput.hide()
	item_display.texture = tex
	item_display.show()
	static_hint.modulate.a = 1.0

# --- UTILS ---
func show_message(txt: String, color: Color = Color.WHITE):
	if message_tween: message_tween.kill() 
	game_message.text = txt
	game_message.modulate = color
	game_message.modulate.a = 0
	message_tween = create_tween()
	message_tween.tween_property(game_message, "modulate:a", 1.0, 0.3)
	message_tween.tween_interval(1.5)
	message_tween.tween_property(game_message, "modulate:a", 0.0, 0.3)

func _input(event):
	if not dimmer.visible: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_unlocked or item_display.visible:
			hide_all()
			overlay_closed.emit()
		elif $Layer_Overlay/CodeInput.visible:
			var mouse_pos = get_viewport().get_mouse_position()
			var code_rect = texture_rect.get_global_rect()
			if not code_rect.has_point(mouse_pos):
				hide_all()
				overlay_closed.emit()

func hide_all():
	dimmer.hide()
	layer_overlay.hide()
	static_hint.modulate.a = 0
	get_tree().paused = false
