extends Area2D

@export var ui_node: CanvasLayer
@export var sprite: Sprite2D # Drag Sprite tangganya ke sini
@export var next_scene_path: String = "res://scenes/area/livingroom.tscn"

# Atur area pijakan tangga di Inspector (misal x tangga di 2000, isi 1950 dan 2050)
@export var x_batas_kiri: float = 1950.0
@export var x_batas_kanan: float = 2050.0

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	if sprite:
		sprite.modulate = Color(1.2, 1.2, 1.2) # Hover putih/terang
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited():
	if sprite:
		sprite.modulate = Color(1, 1, 1) # Normal
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().current_scene.find_child("Player", true, false)
		if player:
			# Cek apakah player berada di dalam range X tangga
			if player.global_position.x >= x_batas_kiri and player.global_position.x <= x_batas_kanan:
				pindah_scene()
			else:
				ui_node.show_message("Posisikan dirimu tepat di depan tangga!", Color.LIGHT_GRAY)

func pindah_scene():
	# Pastikan node ScreenFade ada di UI
	var fade_rect = ui_node.get_node_or_null("ScreenFade")
	if fade_rect:
		fade_rect.show()
		var tween = create_tween()
		tween.tween_property(fade_rect, "self_modulate:a", 1.0, 0.5)
		tween.tween_callback(func(): get_tree().change_scene_to_file(next_scene_path))
	else:
		get_tree().change_scene_to_file(next_scene_path)
