extends CharacterBody2D
class_name PlayerBase

@export var ui_node: CanvasLayer
@export var speed := 300.0
@onready var anim := $AnimatedSprite2D

# --- VARIABEL SISTEM LEMARI ---
var is_hidden := false
var can_move := true
var current_wardrobe: Node2D = null
var pos_before_hide := Vector2.ZERO 

func _ready():
	if Global.is_transitioning:
		# Matikan visual sementara loading, tapi input process tetap nyala
		self.visible = false 
		# Jangan matikan set_physics_process di sini jika ingin input tetap responsif
		# Tapi untuk teleport aman, kita matikan physics movement-nya saja lewat variabel
		can_move = false
		call_deferred("_do_force_teleport")
	else:
		print("Player Ready.")

func _do_force_teleport():
	self.global_position = Global.next_spawn_pos
	if anim: anim.flip_h = Global.next_spawn_flip
	await get_tree().process_frame
	self.visible = true
	can_move = true # Izinkan gerak lagi
	Global.is_transitioning = false

# --- PHYSICS PROCESS ---
func _physics_process(delta: float) -> void:
	# Jika ngumpet, jangan gerak fisiknya, TAPI jangan return total
	# supaya _input masih bisa diproses (tergantung settingan Godot)
	if is_hidden:
		return 

	if not is_on_floor():
		velocity += get_gravity() * delta

	if can_move:
		var direction := Input.get_axis("ui_left", "ui_right")
		handle_movement(direction)
		move_and_slide()

func handle_movement(direction: float):
	if direction != 0:
		velocity.x = direction * speed
		if anim:
			anim.play("walk")
			anim.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		if anim: anim.play("idle")

# ========================================================
#           SISTEM LEMARI (RESET TOTAL)
# ========================================================

func _input(event):
	# Gunakan ui_accept (Spasi/Enter) agar lebih umum
	if is_hidden and event.is_action_pressed("ui_accept"):
		print("Player menekan tombol keluar!") # Debugging
		exit_wardrobe()

func enter_wardrobe_mode(wardrobe_node: Node2D):
	print("Player masuk lemari...")
	# 1. Catat posisi aman
	pos_before_hide = global_position
	
	is_hidden = true
	can_move = false
	current_wardrobe = wardrobe_node
	velocity = Vector2.ZERO
	
	# 2. Pindah ke posisi lemari
	global_position = wardrobe_node.global_position
	
	# 3. Hilangkan visual
	# PENTING: visible = false kadang bikin _input macet di beberapa settingan.
	# Kita gunakan modulate transparan total sebagai alternatif yang lebih aman.
	self.modulate.a = 0.0 
	
	$CollisionShape2D.set_deferred("disabled", true)
	
	if ui_node and ui_node.has_method("show_exit_hint"):
		ui_node.show_exit_hint()

func exit_wardrobe():
	print("Player keluar lemari...")
	if not current_wardrobe: return
	
	# 1. Visual lemari buka
	if current_wardrobe.has_method("force_visual_open"):
		current_wardrobe.force_visual_open()
	
	# 2. Reset Status
	is_hidden = false
	can_move = true
	
	# 3. Kembalikan Posisi (PERSIS ke posisi masuk, jangan digeser +60 dulu)
	# Kalau mau geser, pastikan arahnya benar. Aman-nya balik ke tempat asal.
	global_position = pos_before_hide 
	
	# 4. Munculkan visual lagi
	self.modulate.a = 1.0 # Balikin opacity
	$CollisionShape2D.set_deferred("disabled", false)
	
	if ui_node and ui_node.has_method("hide_exit_hint"):
		ui_node.hide_exit_hint()
	
	current_wardrobe = null
