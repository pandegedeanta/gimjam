extends Area2D

@export var ui_node: CanvasLayer
@export var sprite: Sprite2D 
@export var next_scene_path: String = "res://scenes/area/livingroom.tscn"

@export_group("Target Spawn Settings")
@export var target_pos: Vector2
@export var target_flip: bool = false

@export_group("Interaction Range")
@export var x_batas_kiri: float = 1950.0
@export var x_batas_kanan: float = 2050.0

func _ready():
	# WAJIB ON agar hover kedeteksi
	input_pickable = true 
	
	if ui_node == null:
		ui_node = get_tree().current_scene.find_child("UI", true, false)
	
	# Connect hover signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	if sprite: sprite.modulate = Color(1.3, 1.3, 1.3) # Makin terang saat di-hover
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND) # Jari muncul

func _on_mouse_exited():
	if sprite: sprite.modulate = Color(1, 1, 1)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW) # Balik panah biasa

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().current_scene.find_child("Player", true, false)
		if player:
			if player.global_position.x >= x_batas_kiri and player.global_position.x <= x_batas_kanan:
				pindah_scene_bersama_fade()
			else:
				if ui_node: ui_node.show_message("Posisikan dirimu tepat di depan tangga!", Color.LIGHT_GRAY)

func pindah_scene_bersama_fade():
	# Simpan data spawn ke Global
	Global.next_spawn_pos = target_pos
	Global.next_spawn_flip = target_flip
	Global.is_transitioning = true
	
	if ui_node and ui_node.has_method("fade_out"):
		var fade_tween = ui_node.fade_out()
		# Tunggu layar benar-benar gelap baru ganti scene
		await fade_tween.finished
	
	get_tree().call_deferred("change_scene_to_file", next_scene_path)
