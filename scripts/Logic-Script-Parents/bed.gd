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


enum ItemType { KEY, LETTER }
@export_multiline var letter_text: String = ""
@export var item_type: ItemType = ItemType.KEY

enum State { CLOSED, OPEN_FULL, OPEN_EMPTY }
var current_state = State.CLOSED
var item_taken = false
var can_interact := true

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	update_visual()

func _on_mouse_entered():
	if not can_interact:
		return
	sprite.modulate = Color(1.2, 1.2, 1.2)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited():
	if not can_interact:
		return
	sprite.modulate = Color(1, 1, 1)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

# Buat Event Click Mouse
func _input_event(_viewport, event, _shape_idx):
	if not can_interact:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("AREA DIKLIK")

		var player = get_tree().get_first_node_in_group("Player")
		if not player:
			print("PLAYER TIDAK KETEMU")
			return

# Ukur Jarak Player ke Objek
		var obj_x = sprite.global_position.x
		var player_x = player.global_position.x
		var dist = abs(obj_x - player_x)
		print("OBJ X:", obj_x)
		print("PLAYER X:", player_x)
		print("DIST:", dist)

		if dist <= interaction_dist:
			handle_click()
		else:
			if ui_node:
				ui_node.show_message("Tanganku tidak bisa mencapainya...", Color.LIGHT_GRAY)

# Yang terjadi klo Mouse di Click
func handle_click():
	# 1. Dari CLOSED → OPEN_FULL
	if current_state == State.CLOSED:
		current_state = State.OPEN_FULL
		update_visual()
		return

	# 2. OPEN_FULL → ambil isi
	if current_state == State.OPEN_FULL and not item_taken:
		var atlas = AtlasTexture.new()
		atlas.atlas = sprite.texture
		atlas.region = overlay_rect

		# LETTER: buka isi surat
		if item_type == ItemType.LETTER:
			ui_node.show_letter(letter_text)
			await ui_node.overlay_closed
			ui_node.add_to_inventory("Surat", sprite.texture, overlay_rect)

		# KEY: buka item visual
		elif item_type == ItemType.KEY:
			ui_node.show_item(atlas)
			await ui_node.overlay_closed
			ui_node.add_to_inventory("Kunci Basement", sprite.texture, overlay_rect)

		item_taken = true
		current_state = State.OPEN_EMPTY
		can_interact = false 
		update_visual()


func update_visual():
	if not sprite:
		return

	match current_state:
		State.CLOSED:
			sprite.region_rect = region_closed
		State.OPEN_FULL:
			sprite.region_rect = region_open_full
		State.OPEN_EMPTY:
			sprite.region_rect = region_open_empty
