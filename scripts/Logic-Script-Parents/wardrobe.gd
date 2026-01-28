extends Area2D

@export var ui_node: CanvasLayer
@export var sprite: Sprite2D
@export var interaction_dist: float = 128.0

@export_group("Regions")
@export var region_closed: Rect2
@export var region_open: Rect2
@export var region_hidden: Rect2

enum State { CLOSED, OPEN, HIDDEN }
var current_state := State.CLOSED

signal player_hide_requested(wardrobe: Node2D)
signal player_unhide_requested(wardrobe: Node2D)

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player_hide_requested.connect(player.hide_in_wardrobe)
		player_unhide_requested.connect(player.unhide_from_wardrobe)
	update_visual()

func _on_mouse_entered():
	if current_state == State.HIDDEN:
		return
	sprite.modulate = Color(1.2, 1.2, 1.2)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	if current_state == State.OPEN:
		ui_node.show_hint("Klik untuk bersembunyi")

func _on_mouse_exited():
	sprite.modulate = Color(1, 1, 1)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if current_state == State.HIDDEN:
		return
	ui_node.hide_hint()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var player = get_tree().get_first_node_in_group("Player")
		if not player:
			return

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

func handle_click():
	match current_state:
		State.CLOSED:
			current_state = State.OPEN
			update_visual()

		State.OPEN:
			current_state = State.HIDDEN
			update_visual()
			emit_signal("player_hide_requested", self)

		State.HIDDEN:
			pass

func force_exit():
	if current_state != State.HIDDEN:
		return

	current_state = State.OPEN
	update_visual()
	emit_signal("player_unhide_requested", self)

func update_visual():
	match current_state:
		State.CLOSED:
			sprite.region_rect = region_closed
			ui_node.hide_hint()

		State.OPEN:
			sprite.region_rect = region_open
			sprite.modulate.a = 1.0
			ui_node.show_hint("Klik untuk bersembunyi")

		State.HIDDEN:
			sprite.region_rect = region_hidden
			sprite.modulate.a = 0.5
			ui_node.hide_hint()
