extends Area2D

@export var sprite: Sprite2D
@export var correct_code := "12345"
@export var interaction_dist := 150.0
@export var ui_node: CanvasLayer 

@export_group("Visual Regions")
@export var region_closed: Rect2
@export var region_open_full: Rect2
@export var region_open_empty: Rect2

enum State { CLOSED, OPEN_FULL, OPEN_EMPTY }
var current_state = State.CLOSED
var is_open = false

func _ready():
	input_pickable = true # Pastikan bisa diklik
	
	var saved = Global.get_state(self.name)
	if saved:
		current_state = saved.get("state", State.CLOSED)
		is_open = (current_state != State.CLOSED)
	
	update_visual()
	
	mouse_entered.connect(func():
		if not is_open:
			sprite.modulate = Color(1.2, 1.2, 1.2)
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	)
	mouse_exited.connect(func():
		sprite.modulate = Color.WHITE
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_open: return 
		
		var player = get_tree().get_first_node_in_group("Player")
		if not player: return

		var dist = abs(global_position.x - player.global_position.x)
		if dist <= interaction_dist:
			if ui_node:
				ui_node.show_safe_panel(self, correct_code)
			else:
				print("ERROR: UI Node belum di-assign di Brankas!")
		else:
			if ui_node: ui_node.show_message("Terlalu jauh...", Color.LIGHT_GRAY)

func open():
	if is_open: return
	is_open = true
	current_state = State.OPEN_FULL
	update_visual()
	Global.save_state(self.name, {"state": current_state})

func update_visual():
	if not sprite: return
	sprite.region_enabled = true
	match current_state:
		State.CLOSED: sprite.region_rect = region_closed
		State.OPEN_FULL: sprite.region_rect = region_open_full
		State.OPEN_EMPTY: sprite.region_rect = region_open_empty
