extends Area2D

@export_group("UI & Visual")
@export var ui_node: CanvasLayer
@export var sprite: Sprite2D
@export var wall_mid: StaticBody2D
@export var koordinat_buka: Rect2
@export var koordinat_tutup: Rect2 
@export var jarak_toleransi: float = 128.0

@export_group("Camera Limits")
@export var bedroom_limit_left: int = -50     
@export var bedroom_limit_right: int = 1200 
@export var hall_limit_left: int = 1100       
@export var hall_limit_right: int = 2400

@export_group("Ambang Pintu (Tembok)")
@export var door_x_min: float = 1100.0
@export var door_x_max: float = 1200.0

var sudah_di_unlock: bool = false 
var is_open: bool = false

func _ready():
	# Gabungkan signal hover agar bersih
	mouse_entered.connect(func(): 
		sprite.modulate = Color(1.2, 1.2, 1.2)
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	)
	mouse_exited.connect(func(): 
		sprite.modulate = Color(1, 1, 1)
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	)
	
	if wall_mid: 
		wall_mid.set_collision_layer_value(1, true)
	
	# Lock kamera awal ke Bedroom
	await get_tree().process_frame
	var player = get_tree().current_scene.find_child("Player", true, false)
	if player: 
		player.lock_camera(bedroom_limit_left, bedroom_limit_right, false)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().current_scene.find_child("Player", true, false)
		if not player: return

		# CEK JARAK
		if abs(player.global_position.x - self.global_position.x) > jarak_toleransi:
			ui_node.show_message("Terlalu jauh untuk menjangkau pintu...", Color.LIGHT_GRAY)
			return

		eksekusi_pintu(player)

func eksekusi_pintu(player):
	if not sudah_di_unlock:
		if "Kunci Kamar" in ui_node.inventory_items:
			sudah_di_unlock = true
			ui_node.remove_from_inventory("Kunci Kamar")
			buka_pintu(player)
			ui_node.show_message("Pintu Terbuka!", Color.AQUAMARINE)
		else:
			ui_node.show_message("Pintu Terkunci...", Color.CORAL)
		return

	if is_open:
		# CEK APAKAH PEMAIN DI TENGAH PINTU (Area Tembok)
		if player.global_position.x > door_x_min and player.global_position.x < door_x_max:
			ui_node.show_message("Pintu terhalang badanmu!", Color.CORAL)
		else:
			tutup_pintu(player)
	else:
		buka_pintu(player)

func buka_pintu(player):
	is_open = true
	sprite.region_rect = koordinat_buka
	if wall_mid: 
		wall_mid.set_collision_layer_value(1, false)
	# Bebaskan kamera saat pintu buka
	player.unlock_camera_limits(bedroom_limit_left, hall_limit_right)

func tutup_pintu(player):
	is_open = false
	sprite.region_rect = koordinat_tutup
	if wall_mid: 
		wall_mid.set_collision_layer_value(1, true)
	
	# Lock kamera berdasarkan sisi mana player berada
	if player.global_position.x <= door_x_min:
		player.lock_camera(bedroom_limit_left, bedroom_limit_right, true)
	else:
		player.lock_camera(hall_limit_left, hall_limit_right, true)
