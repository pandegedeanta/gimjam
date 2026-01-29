extends Area2D

@export var sprite: Sprite2D
@export var next_scene_path: String
@export var interaction_dist := 128.0

@onready var ui_node := get_tree().get_first_node_in_group("UI")

func _ready():
	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	sprite.modulate = Color(1.2, 1.2, 1.2)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

	if ui_node:
		ui_node.toggle_stair_text(true)

func _on_mouse_exited():
	sprite.modulate = Color.WHITE
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

	if ui_node:
		ui_node.toggle_stair_text(false)

func _input_event(_viewport, event, _shape_idx):
	#print("INPUT EVENT TERPANGGIL:", event)
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:

		print("STAIRS DIKLIK") 
		var player = get_tree().get_first_node_in_group("Player")
		if not player:
			print("PLAYER NULL")
			return

		var dist = abs(sprite.global_position.x - player.global_position.x)

		if dist >= interaction_dist:
			print("MASUK KONDISI TERLALU JAUH")
			if ui_node:
				ui_node.show_message("Terlalu jauh untuk naik tangga.")
			return

		start_transition()

func start_transition():
	if ui_node:
		ui_node.toggle_stair_text(false)
		ui_node.fade_out()
		await ui_node.fade_finished

	get_tree().change_scene_to_file(next_scene_path)
