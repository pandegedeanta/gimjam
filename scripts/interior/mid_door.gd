extends Area2D

@export_group("UI & Visual")
@export var ui_node: CanvasLayer
@export var sprite: Sprite2D
@export var wall_mid: StaticBody2D
@export var koordinat_buka: Rect2
@export var koordinat_tutup: Rect2 
@export var jarak_toleransi: float = 128.0

@export_group("Door Settings")
@export var terkunci_secara_default: bool = true 
@export var nama_kunci_pasangan: String = "Kunci Kamar"
@export var pesan_terkunci: String = "Terkunci."

@export_group("Room Darkeners")
@export var bedroom_darkener: ColorRect 
@export var hall_darkener: ColorRect    

@export_group("Light Clipping")
@export var bedroom_light_frame: Control 
@export var hall_light_frame: Control    

@export_group("Ambang Pintu")
@export var door_x_min: float = 1100.0
@export var door_x_max: float = 1200.0

var sudah_di_unlock: bool = false 
var is_open: bool = false

func _ready():
	input_pickable = true
	
	var saved = Global.get_state(self.name)
	if saved:
		sudah_di_unlock = saved.get("unlocked", false)
		is_open = saved.get("is_open", false)
	else:
		sudah_di_unlock = not terkunci_secara_default 
		is_open = false
	
	update_visual_state()
	_sync_darkener_delayed() 
	
	mouse_entered.connect(func(): 
		if ui_node and ui_node.has_method("is_blocking_input"):
			if ui_node.is_blocking_input(): return
		
		if sprite: sprite.modulate = Color(1.3, 1.3, 1.3)
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	)
	
	mouse_exited.connect(func(): 
		if sprite: sprite.modulate = Color(1, 1, 1)
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	)

func update_visual_state():
	if is_open:
		if sprite: sprite.region_rect = koordinat_buka
		if wall_mid: wall_mid.set_collision_layer_value(1, false) 
		
		if bedroom_darkener: bedroom_darkener.hide()
		if hall_darkener: hall_darkener.hide()
		_set_lights_clipping(false)
	else:
		if sprite: sprite.region_rect = koordinat_tutup
		if wall_mid: wall_mid.set_collision_layer_value(1, true) 
		_set_lights_clipping(true)

func _sync_darkener_delayed():
	await get_tree().create_timer(0.2).timeout
	var player = get_tree().current_scene.find_child("Player", true, false)
	if player: update_darkeners(player)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if ui_node and ui_node.has_method("is_blocking_input") and ui_node.is_blocking_input(): return

		var player = get_tree().current_scene.find_child("Player", true, false)
		if not player: return
		
		if abs(player.global_position.x - self.global_position.x) > jarak_toleransi:
			if ui_node: ui_node.show_message("Terlalu jauh...", Color.WHITE)
			return
		eksekusi_pintu(player)

func eksekusi_pintu(player):
	if not sudah_di_unlock:
		if ui_node.selected_item_name == nama_kunci_pasangan:
			sudah_di_unlock = true
			ui_node.remove_from_inventory(nama_kunci_pasangan)
			
			play_key_sfx()   
			await get_tree().create_timer(0.2).timeout
			
			buka_pintu()
			ui_node.show_message("Terbuka!", Color.WHITE)
			_save_state()
		elif ui_node.selected_item_name == "":
			ui_node.show_message(pesan_terkunci, Color.WHITE)
		else:
			ui_node.show_message("Kunci tidak cocok.", Color.WHITE)
		return

	if is_open:
		if player.global_position.x > door_x_min and player.global_position.x < door_x_max:
			ui_node.show_message("Minggir dulu.", Color.WHITE)
		else:
			tutup_pintu(player)
	else:
		buka_pintu()
	
	_save_state()

func buka_pintu():
	is_open = true
	
	if $AudioStreamPlayer:
		$AudioStreamPlayer.play()
		
	update_visual_state()

func tutup_pintu(player):
	is_open = false
	
	if $AudioStreamPlayer:
		$AudioStreamPlayer.play()
	
	update_visual_state()
	update_darkeners(player)

func play_key_sfx():
	if $AudioStreamPlayer_Key:
		$AudioStreamPlayer_Key.play()


func update_darkeners(player):
	if is_open: return 
	if not bedroom_darkener or not hall_darkener: return 
	
	# Jika player di kiri pintu (Bedroom), kanan gelap (Hall)
	if player.global_position.x < (door_x_min + door_x_max) / 2.0:
		bedroom_darkener.hide()
		hall_darkener.show()
	else:
		bedroom_darkener.show()
		hall_darkener.hide()

func _set_lights_clipping(enabled: bool):
	if bedroom_light_frame: bedroom_light_frame.clip_contents = enabled
	if hall_light_frame: hall_light_frame.clip_contents = enabled

func _save_state():
	Global.save_state(self.name, {"unlocked": sudah_di_unlock, "is_open": is_open})
