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

func _ready():
	dimmer.hide()
	layer_overlay.hide()
	static_hint.modulate.a = 0
	game_message.modulate.a = 0
	# PENTING: Mencegah dimmer memblokir klik di awal
	dimmer.mouse_filter = Control.MOUSE_FILTER_PASS 
	setup_dial_system()

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

# --- FUNGSI INVENTORY YANG TADI HILANG ---
func add_to_inventory(item_name: String, item_tex: Texture, item_region: Rect2):
	var slot = TextureButton.new()
	slot.name = item_name
	slot.custom_minimum_size = Vector2(64, 64) 
	slot.ignore_texture_size = true
	slot.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var atlas = AtlasTexture.new()
	atlas.atlas = item_tex
	atlas.region = item_region
	slot.texture_normal = atlas
	
	slot.pressed.connect(_on_inventory_slot_pressed.bind(item_name, atlas))
	inventory_bar.add_child(slot)
	inventory_items.append(item_name)
	
	if "Global" in self.get_tree().root:
		Global.add_item(item_name)

func _on_inventory_slot_pressed(item_name: String, tex: Texture):
	if "Kertas" in item_name:
		show_item(tex)
	else:
		show_message("Ini adalah " + item_name)

func remove_from_inventory(item_name: String):
	if item_name in inventory_items:
		var slot = inventory_bar.get_node_or_null(item_name)
		if slot:
			slot.queue_free()
		inventory_items.erase(item_name)
		if "Global" in self.get_tree().root:
			Global.remove_item(item_name)

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
