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

@export var region_tutup: Rect2 
@export var region_buka: Rect2

var target_code: String = "1234"
var is_unlocked: bool = false
var message_tween: Tween 
var inventory_items = []

func _ready():
	# Sembunyikan elemen overlay satu per satu agar CanvasLayer tetap aktif
	dimmer.hide()
	layer_overlay.hide()
	static_hint.modulate.a = 0
	game_message.modulate.a = 0
	inventory_bar.show() # Inventory selalu standby
	
	if hbox:
		for i in range(hbox.get_child_count()):
			hbox.get_child(i).text_changed.connect(_on_box_text_changed.bind(i))

func show_message(txt: String, color: Color = Color.WHITE):
	if message_tween:
		message_tween.kill() # Reset durasi pesan jika diklik berkali-kali
	
	game_message.text = txt
	game_message.modulate = color
	game_message.modulate.a = 0
	
	message_tween = create_tween()
	message_tween.tween_property(game_message, "modulate:a", 1.0, 0.3)
	message_tween.tween_interval(1.5)
	message_tween.tween_property(game_message, "modulate:a", 0.0, 0.3)

func show_gembok(correct_code: String):
	get_tree().paused = true
	target_code = correct_code
	is_unlocked = false
	texture_rect.texture.region = region_tutup
	
	inventory_bar.hide() # Sembunyikan inventory saat fokus puzzle
	dimmer.show()
	layer_overlay.show()
	$Layer_Overlay/CodeInput.show()
	item_display.hide()
	static_hint.modulate.a = 0
	
	for box in hbox.get_children():
		box.text = ""
		box.editable = true
	hbox.get_child(0).grab_focus()

func _on_box_text_changed(new_text: String, index: int):
	if is_unlocked: return
	if new_text.length() == 1 and index < 3:
		hbox.get_child(index + 1).grab_focus()
	
	var full_code = ""
	for box in hbox.get_children(): full_code += box.text
	
	if full_code.length() == 4:
		if full_code == target_code:
			is_unlocked = true
			texture_rect.texture.region = region_buka
			show_message("Terbuka", Color.GREEN_YELLOW)
			static_hint.modulate.a = 1.0
			code_correct.emit()
		else:
			show_message("Kode Salah", Color.TOMATO)

func show_item(tex: Texture):
	inventory_bar.hide() # Sembunyikan inventory saat melihat item besar
	dimmer.show()
	layer_overlay.show()
	$Layer_Overlay/CodeInput.hide()
	item_display.texture = tex
	item_display.show()
	static_hint.modulate.a = 1.0

func _input(event):
	if not dimmer.visible: return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Jika gembok terbuka atau melihat item, klik mana saja untuk tutup
		if is_unlocked or item_display.visible:
			hide_all()
			overlay_closed.emit()
		
		# KHUSUS SAAT INPUT KODE: 
		# Hanya tutup jika klik di area "Dimmer" (luar kotak gembok)
		elif $Layer_Overlay/CodeInput.visible:
			# Jika yang diklik adalah background gelap (Dimmer), maka Batal
			# Kita gunakan get_viewport().get_mouse_position() untuk cek klik
			var mouse_pos = get_viewport().get_mouse_position()
			var code_rect = $Layer_Overlay/CodeInput/TextureRect.get_global_rect()
			
			if not code_rect.has_point(mouse_pos):
				hide_all()
				overlay_closed.emit()

func hide_all():
	dimmer.hide()
	layer_overlay.hide()
	static_hint.modulate.a = 0
	inventory_bar.show() # Tampilkan kembali inventory
	get_tree().paused = false

func add_to_inventory(item_name: String, item_tex: Texture, item_region: Rect2):
	var slot = TextureButton.new()
	slot.name = item_name
	slot.custom_minimum_size = Vector2(64, 64) 
	slot.ignore_texture_size = true
	slot.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	
	var atlas = AtlasTexture.new()
	atlas.atlas = item_tex
	atlas.region = item_region
	slot.texture_normal = atlas
	
	slot.pressed.connect(_on_inventory_slot_pressed.bind(item_name, atlas))
	inventory_bar.add_child(slot)
	inventory_items.append(item_name)

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
