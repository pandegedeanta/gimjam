extends Area2D

@export var ui_node: CanvasLayer
@export var sprite: Sprite2D
@export var koordinat_buka: Rect2
@export var jarak_toleransi: float = 128.0 # Pastikan dideklarasi!
@export var next_scene_path: String = "res://scenes/area/hall.tscn"

var is_open: bool = false
var transitioning: bool = false

func _ready():
	# Hubungkan signal untuk deteksi badan dan hover
	body_entered.connect(_on_body_entered)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	# Warna berubah hanya jika belum terbuka
	if not is_open:
		sprite.modulate = Color(1.2, 1.2, 1.2)
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited():
	sprite.modulate = Color(1, 1, 1)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		eksekusi_pintu()

func eksekusi_pintu():
	# Cek apakah sudah terbuka atau sedang transisi
	if is_open or transitioning or ui_node == null:
		return

	var player = get_tree().current_scene.find_child("Player", true, false)
	if player:
		var jarak = abs(player.global_position.x - global_position.x)
		
		# 1. Validasi Jarak
		if jarak > jarak_toleransi:
			ui_node.show_message("Tanganku tak sampai...", Color.LIGHT_GRAY)
			return

		# 2. Validasi Kunci
		if "Kunci Kamar" in ui_node.inventory_items:
			is_open = true
			ui_node.show_message("Pintu Terbuka!", Color.AQUAMARINE)
			sprite.region_rect = koordinat_buka
			ui_node.remove_from_inventory("Kunci Kamar")
			
			# Matikan input pickable agar tidak bisa diklik lagi
			input_pickable = false
			# Reset kursor
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		else:
			ui_node.show_message("Terkunci rapat...", Color.CORAL)

func _on_body_entered(body):
	# Terpicu saat player menabrak pintu yang SUDAH terbuka
	if is_open and body.name == "Player" and not transitioning:
		mulai_transisi(body)

func mulai_transisi(player):
	transitioning = true
	
	# Matikan kontrol manual di player.gd
	if "is_transitioning" in player:
		player.is_transitioning = true 
	
	# Matikan tabrakan agar bisa menembus batas world (Wall_Right)
	player.set_collision_layer_value(1, false)
	player.set_collision_mask_value(1, false)
	
	# Play animasi jalan
	if player.anim:
		player.anim.play("walk")
	
	var fade_rect = ui_node.get_node("ScreenFade")
	fade_rect.show() 
	
	var tween = create_tween().set_parallel(true)
	# Seret player ke kanan melewati batas kamera
	tween.tween_property(player, "global_position:x", player.global_position.x + 400, 2.0)
	# Efek layar menghitam
	tween.tween_property(fade_rect, "self_modulate:a", 1.0, 1.5).set_delay(0.5)
	
	tween.chain().tween_callback(func():
		print("Mencoba pindah ke: ", next_scene_path)
		var err = get_tree().change_scene_to_file(next_scene_path)
		if err != OK:
			print("GAGAL PINDAH! Error Code: ", err)
			fade_rect.self_modulate.a = 0
			transitioning = false
			if "is_transitioning" in player:
				player.is_transitioning = false
	)
