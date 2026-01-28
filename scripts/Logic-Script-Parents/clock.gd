extends Area2D

@export var sprite: Sprite2D
@export var interaction_dist := 128.0
@export var ui_node: CanvasLayer
@export var sound_player: AudioStreamPlayer2D
@export var noise_radius := 600.0

signal noise_emitted(position: Vector2, radius: float)

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	if sound_player:
		sound_player.finished.connect(_on_sound_finished)

func _input_event(_viewport, event, _shape_idx):
	if sound_player and sound_player.playing:
		return

	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:

		var player = get_tree().get_first_node_in_group("Player")
		if not player:
			return

		var dist = abs(sprite.global_position.x - player.global_position.x)

		if dist <= interaction_dist:
			ring_clock()
		else:
			ui_node.show_message(
				"Tanganku tidak bisa mencapainya...",
				Color.LIGHT_GRAY
			)

func _on_mouse_entered():
	if sound_player and sound_player.playing:
		return

	sprite.self_modulate = Color(1.25, 1.25, 1.25)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited():
	sprite.self_modulate = Color.WHITE
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func ring_clock():
	if sound_player and sound_player.stream:
		sound_player.play()

	emit_signal("noise_emitted", global_position, noise_radius)
	sprite.self_modulate = Color(0.8, 0.8, 0.8)

func _on_sound_finished():
	# RESET VISUAL & CURSOR
	sprite.self_modulate = Color.WHITE
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
