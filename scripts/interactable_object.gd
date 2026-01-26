class_name InteractableObject extends Area2D

@export_group("References")
@export var ui_node: CanvasLayer
@export var sprite: Sprite2D

@export_group("Overlay Settings")
@export var overlay_rect: Rect2

@export_group("Lock Settings")
@export var is_locked: bool = false
@export var correct_code: String = "1234"

@export_group("Sprite Regions")
@export var region_closed: Rect2
@export var region_open_full: Rect2
@export var region_open_empty: Rect2

@export var interaction_dist: float = 150.0

enum State { CLOSED, OPEN_FULL, OPEN_EMPTY }
var current_state = State.CLOSED
var item_taken = false

func _ready():
	update_visual()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().current_scene.find_child("Player", true, false)
		var can_interact = true
		
		if player:
			var dist_x = abs(global_position.x - player.global_position.x)
			can_interact = dist_x <= interaction_dist
		
		if can_interact:
			handle_click()
		else:
			print("Benda: Kamu terlalu jauh untuk menjangkau ini.")

func handle_click():
	if current_state == State.CLOSED:
		if is_locked:
			ui_node.show_code_input()
			# Menunggu sinyal dari UI
			var input = await ui_node.code_entered
			print("Laci: Menerima input '", input, "'. Kode benar: '", correct_code, "'")
			
			if str(input) == str(correct_code):
				is_locked = false
				current_state = State.OPEN_FULL
				print("Laci: KODE BENAR!")
			else:
				print("Laci: KODE SALAH!")
		else:
			current_state = State.OPEN_EMPTY if item_taken else State.OPEN_FULL
	
	elif current_state == State.OPEN_FULL:
		var atlas = AtlasTexture.new()
		atlas.atlas = sprite.texture
		atlas.region = overlay_rect
		ui_node.show_item(atlas)
		
		item_taken = true
		current_state = State.OPEN_EMPTY
		# Update gambar sebelum await supaya barang langsung hilang di background
		update_visual()
		await ui_node.overlay_closed
		
	elif current_state == State.OPEN_EMPTY:
		current_state = State.CLOSED

	update_visual()

func update_visual():
	if not sprite: return
	match current_state:
		State.CLOSED: sprite.region_rect = region_closed
		State.OPEN_FULL: sprite.region_rect = region_open_full
		State.OPEN_EMPTY: sprite.region_rect = region_open_empty
