extends Area2D

@export var ui_node: CanvasLayer
@export var sprite: Sprite2D
@export var interaction_dist: float = 150.0

@export_group("Regions")
@export var region_closed: Rect2
@export var region_open: Rect2
@export var region_hidden: Rect2 

enum State { CLOSED, OPEN, HIDDEN }
var current_state = State.CLOSED

# HAPUS SEMUA BARIS "SIGNAL" DI SINI. KITA TIDAK PAKAI LAGI.

func _ready():
	input_pickable = true 
	
	# Hover Effect
	mouse_entered.connect(func():
		if sprite: sprite.modulate = Color(1.2, 1.2, 1.2)
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		if current_state == State.OPEN and ui_node:
			ui_node.show_hint("Klik untuk bersembunyi")
		elif current_state == State.HIDDEN and ui_node:
			ui_node.show_hint("Klik untuk keluar") # Tambahan Hint
	)
	
	mouse_exited.connect(func():
		if sprite: sprite.modulate = Color(1, 1, 1)
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		if ui_node: ui_node.hide_hint()
	)
	
	update_visual()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().get_first_node_in_group("Player")
		if not player: return
		
		# Cek Jarak (Kecuali kalau lagi didalam, jarak pasti 0)
		if current_state != State.HIDDEN:
			if abs(global_position.x - player.global_position.x) > interaction_dist:
				if ui_node: ui_node.show_message("Terlalu jauh...", Color.LIGHT_GRAY)
				return
		
		# LOGIKA KLIK
		match current_state:
			State.CLOSED:
				# Klik 1: Buka Pintu
				current_state = State.OPEN
				update_visual()
			
			State.OPEN:
				# Klik 2: Masuk Lemari
				current_state = State.HIDDEN
				update_visual()
				player.enter_wardrobe_mode(self)
			
			State.HIDDEN:
				# Klik 3: KELUAR (Fitur Baru!)
				# Kita panggil fungsi keluar punya player
				player.exit_wardrobe()

# Dipanggil oleh Player saat dia keluar (baik via tombol Enter atau Klik)
func force_visual_open():
	current_state = State.OPEN
	update_visual()

func update_visual():
	if not sprite: return
	
	match current_state:
		State.CLOSED:
			sprite.region_rect = region_closed
			sprite.modulate.a = 1.0 
			if ui_node: ui_node.hide_hint()

		State.OPEN:
			sprite.region_rect = region_open
			sprite.modulate.a = 1.0 
			if ui_node: ui_node.show_hint("Klik untuk bersembunyi")

		State.HIDDEN:
			sprite.region_rect = region_hidden
			sprite.modulate.a = 0.5 
			if ui_node: ui_node.show_hint("Klik / Enter untuk keluar")
