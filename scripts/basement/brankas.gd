extends Area2D

@export var sprite: Sprite2D
@export var correct_code := "12345"
@export var interaction_dist := 128.0
var frame_regions := []
@export var total_frames := 3
@export var region_closed: Rect2
@export var region_open_full: Rect2
@export var region_open_empty: Rect2
@export var overlay_rect: Rect2

@onready var ui := get_tree().get_first_node_in_group("UI")

enum State { CLOSED, OPEN_FULL, OPEN_EMPTY }
var current_state = State.CLOSED

var current_frame := 0
var anim_timer := 0.0
var anim_speed := 0.1 # detik per frame
var is_opening := false
var is_open := false

func _ready():
	frame_regions = [region_closed, region_open_full, region_open_empty]
	input_pickable = true
	sprite.region_enabled = true
	sprite.region_rect = region_closed  # mulai dari state CLOSED
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func open():
	if is_open: return
	is_open = true
	current_state = State.OPEN_FULL
	update_visual()
	if ui:
		ui.hide_hint()

func update_visual():
	if not sprite: return
	sprite.region_enabled = true
	match current_state:
		State.CLOSED:
			sprite.region_rect = region_closed
		State.OPEN_FULL:
			sprite.region_rect = region_open_full
		State.OPEN_EMPTY:
			sprite.region_rect = region_open_empty


func _process(delta):
	if is_opening:
		anim_timer += delta
		if anim_timer >= anim_speed:
			anim_timer -= anim_speed
			current_frame += 1
			if current_frame >= total_frames:
				current_frame = total_frames - 1
				is_opening = false
			sprite.region_rect = frame_regions[current_frame]


func _on_mouse_entered():
	if is_open: return
	sprite.modulate = Color(1.2, 1.2, 1.2)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	if ui:
		ui.show_hint("Klik untuk membuka brankas")

func _on_mouse_exited():
	sprite.modulate = Color.WHITE
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if ui:
		ui.hide_hint()

func _input_event(_viewport, event, _shape_idx):
	if is_open: return

	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:

		var player = get_tree().get_first_node_in_group("Player")
		if not player: return

		var dist = abs(sprite.global_position.x - player.global_position.x)
		if dist > interaction_dist:
			ui.show_message("Terlalu jauh dari brankas")
			return

		ui.show_code_input(self)
