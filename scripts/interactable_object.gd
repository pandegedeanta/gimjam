extends Area2D

@export var ui_node: CanvasLayer
@export var sprite: Sprite2D
@export var is_locked: bool = false
@export var correct_code: String = "1234"
@export var interaction_dist: float = 128.0 

@export_group("Regions")
@export var region_closed: Rect2
@export var region_open_full: Rect2
@export var region_open_empty: Rect2
@export var overlay_rect: Rect2

enum State { CLOSED, OPEN_FULL, OPEN_EMPTY }
var current_state = State.CLOSED
var item_taken = false

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	update_visual()

func _on_mouse_entered():
	sprite.modulate = Color(1.2, 1.2, 1.2)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited():
	sprite.modulate = Color(1, 1, 1)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		var player = get_tree().current_scene.find_child("Player", true, false)
		if player:
			var dist = abs(global_position.x - player.global_position.x)
			if dist <= interaction_dist:
				handle_click()
			else:
				ui_node.show_message("Terlalu jauh untuk menjangkau ini.", Color.LIGHT_GRAY)

func handle_click():
	if current_state == State.CLOSED:
		if is_locked:
			ui_node.show_gembok(correct_code)
			await ui_node.overlay_closed
			if ui_node.is_unlocked:
				is_locked = false
				current_state = State.OPEN_FULL
		else:
			current_state = State.OPEN_EMPTY if item_taken else State.OPEN_FULL
	
	elif current_state == State.OPEN_FULL:
		var atlas = AtlasTexture.new()
		atlas.atlas = sprite.texture
		atlas.region = overlay_rect
		ui_node.show_item(atlas)
		
		await ui_node.overlay_closed
		
		# Logika Deteksi Node "Drawer"
		var nama_item = "Kertas"
		if "Drawer" in name or "drawer" in name: 
			nama_item = "Kunci Kamar"
		
		ui_node.add_to_inventory(nama_item, sprite.texture, overlay_rect)
		item_taken = true
		current_state = State.OPEN_EMPTY
		print("DEBUG: " + nama_item + " diambil!")
		
	elif current_state == State.OPEN_EMPTY:
		current_state = State.CLOSED

	update_visual()

func update_visual():
	if not sprite: return
	match current_state:
		State.CLOSED: sprite.region_rect = region_closed
		State.OPEN_FULL: sprite.region_rect = region_open_full
		State.OPEN_EMPTY: sprite.region_rect = region_open_empty
