extends Area2D

@export_group("UI & Visual")
@export var ui_node: CanvasLayer
@export var sprite: Sprite2D
@export var wall_collision: StaticBody2D
@export var koordinat_buka: Rect2
@export var koordinat_tutup: Rect2 
@export var jarak_toleransi: float = 128.0

@export_group("Room Darkeners")
@export var parents_room_darkener: ColorRect
@export var hall_darkener: ColorRect        

@export_group("Light Clipping")
@export var parents_light_frame: Control

@export_group("Interaction Settings")
@export var item_perusak: String = "Palu"
@export var door_x_min: float = 1800.0
@export var door_x_max: float = 1950.0

var sudah_jebol: bool = false 
var is_open: bool = false

func _ready():
	# Cek progres dari Global
	var saved = Global.get_state(self.name)
	if saved:
		sudah_jebol = saved["unlocked"]
		if sudah_jebol:
			is_open = true
			sprite.region_rect = koordinat_buka
			if wall_collision: wall_collision.set_collision_layer_value(1, false)
			_set_lights_clipping(false)

	mouse_entered.connect(func(): 
		sprite.modulate = Color(1.2, 1.2, 1.2)
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	)
	mouse_exited.connect(func(): 
		sprite.modulate = Color(1, 1, 1)
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	)
	
	if wall_collision and not is_open: 
		wall_collision.set_collision_layer_value(1, true)
	
	_set_lights_clipping(not is_open)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().current_scene.find_child("Player", true, false)
		if not player: return
		if abs(player.global_position.x - self.global_position.x) > jarak_toleransi:
			ui_node.show_message("Terlalu jauh...", Color.LIGHT_GRAY)
			return
		eksekusi_pintu_ortu(player)

func eksekusi_pintu_ortu(player):
	if not sudah_jebol:
		if ui_node.selected_item_name == item_perusak:
			sudah_jebol = true
			Global.save_state(self.name, {"unlocked": true})
			buka_pintu()
			ui_node.show_message("BRAKK! Engsel pintu hancur.", Color.ORANGE_RED)
		elif ui_node.selected_item_name == "":
			ui_node.show_message("Pintu ini terkunci rapat dari dalam...", Color.CORAL)
		else:
			ui_node.show_message("Tidak dapat membuka pintu dengan ini.", Color.LIGHT_GRAY)
		return

	if is_open:
		if player.global_position.x > door_x_min and player.global_position.x < door_x_max:
			ui_node.show_message("Pintu terhalang badanmu!", Color.CORAL)
		else:
			tutup_pintu(player)
	else:
		buka_pintu()

func buka_pintu():
	is_open = true
	sprite.region_rect = koordinat_buka
	if wall_collision: wall_collision.set_collision_layer_value(1, false)
	_set_lights_clipping(false)
	if parents_room_darkener: parents_room_darkener.hide()
	if hall_darkener: hall_darkener.hide()

func tutup_pintu(player):
	is_open = false
	sprite.region_rect = koordinat_tutup
	if wall_collision: wall_collision.set_collision_layer_value(1, true)
	_set_lights_clipping(true)
	if player.global_position.x <= door_x_min:
		if parents_room_darkener: parents_room_darkener.show()
		if hall_darkener: hall_darkener.hide()
	else:
		if parents_room_darkener: parents_room_darkener.hide()
		if hall_darkener: hall_darkener.show()

func _set_lights_clipping(enabled: bool):
	if parents_light_frame:
		parents_light_frame.clip_contents = enabled
