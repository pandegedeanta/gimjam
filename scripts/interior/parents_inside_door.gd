extends Area2D

@export_group("References")
@export var ui_node: CanvasLayer
@export var sprite: Sprite2D

@export_group("Visual Settings")
@export var region_closed: Rect2
@export var region_open: Rect2

@export_group("Navigation")
@export_file("*.tscn") var scene_tujuan # Masukkan bedroom.tscn disini
@export var spawn_pos_tujuan: Vector2 # Titik muncul di bedroom (misal depan pintu)
@export var flip_player_at_spawn: bool = false 

var is_open: bool = false
var is_exiting: bool = false # Supaya gak trigger berkali-kali

func _ready():
	# Default: Tertutup saat scene mulai
	is_open = false
	update_visual()
	
	mouse_entered.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
	mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))

# --- 1. LOGIKA KLIK (BUKA / TUTUP PINTU) ---
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_exiting: return # Jangan bisa klik kalau lagi animasi keluar
		
		# Cek jarak player (opsional)
		var player = get_tree().current_scene.find_child("Player", true, false)
		if player and abs(player.global_position.x - global_position.x) > 200:
			ui_node.show_message("Terlalu jauh...", Color.LIGHT_GRAY)
			return

		# Toggle Buka/Tutup
		is_open = not is_open
		update_visual()
		
		if is_open:
			pass # ui_node.show_message("Pintu Terbuka", Color.WHITE)
		else:
			pass # ui_node.show_message("Pintu Tertutup", Color.WHITE)

func update_visual():
	if is_open:
		sprite.region_rect = region_open
	else:
		sprite.region_rect = region_closed

# --- 2. LOGIKA TRIGGER (JALAN KE KIRI) ---
# Hubungkan signal body_entered dari Area2D "ExitTrigger" ke fungsi ini
func _on_exit_trigger_body_entered(body):
	if body.name == "Player" and not is_exiting:
		# LOGIKA UTAMA:
		# Kalau Pintu TERBUKA -> Jalankan Auto-Walk Exit
		# Kalau Pintu TERTUTUP -> Player bakal mentok tembok secara alami (Physics), jadi biarkan saja.
		if is_open:
			start_auto_exit(body)
		else:
			ui_node.show_message("Pintu masih tertutup.", Color.CORAL)

func start_auto_exit(player):
	print("Mulai Auto-Exit Sequence...")
	is_exiting = true
	Global.is_transitioning = true
	
	# 1. Matikan Kontrol Player
	player.set_physics_process(false)
	
	# 2. Matikan Collision Player (Supaya tembus WorldBoundary/CameraLimit)
	# PENTING: Gunakan set_deferred agar aman
	player.get_node("CollisionShape2D").set_deferred("disabled", true)
	
	# 3. Paksa Animasi Jalan ke Kiri
	if player.anim:
		player.anim.play("walk")
		player.anim.flip_h = true # Hadap Kiri
	
	# 4. Gerakkan Player Keluar Layar (Tween ke kiri sejauh 200-300 pixel)
	var target_x = player.global_position.x - 300 
	var tween = create_tween()
	tween.tween_property(player, "global_position:x", target_x, 2.0) # Jalan selama 2 detik
	
	# 5. Fade Out Layar
	ui_node.fade_out()
	
	# 6. Pindah Scene
	await tween.finished
	
	Global.next_spawn_pos = spawn_pos_tujuan
	Global.next_spawn_flip = flip_player_at_spawn
	
	if scene_tujuan:
		get_tree().change_scene_to_file(scene_tujuan)
	else:
		print("ERROR: Scene tujuan belum diisi di Inspector!")
		# Emergency unlock biar gak softlock kalau lupa isi scene
		Global.is_transitioning = false
		player.set_physics_process(true)
