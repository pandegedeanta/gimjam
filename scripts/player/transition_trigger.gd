extends Area2D

@export_file("*.tscn") var scene_tujuan
@export var koordinat_tujuan: Vector2 
@export var harus_flip: bool = false

func _ready():
	input_pickable = true # Agar kursor bisa berinteraksi

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Global.next_spawn_pos = koordinat_tujuan
		Global.next_spawn_flip = harus_flip
		Global.is_transitioning = true
		
		# Gunakan call_deferred untuk pindah scene
		get_tree().call_deferred("change_scene_to_file", scene_tujuan)
