extends CharacterBody2D
class_name PlayerBase

@export var speed := 300.0
@onready var anim := $AnimatedSprite2D

func _ready():
	# Jika kita datang dari scene lain (transisi aktif)
	if Global.is_transitioning:
		# 1. Benar-benar lumpuhkan player agar tidak terpengaruh gravitasi/physics posisi lama
		self.visible = false
		set_physics_process(false) 
		
		# 2. Antrekan pemindahan posisi di akhir frame ini
		call_deferred("_do_force_teleport")
	else:
		# Jika baru pertama kali play game (bukan pindah scene)
		print("Player di posisi awal scene.")

func _do_force_teleport():
	# 3. Paksa posisi global ke koordinat tujuan yang sudah dititip di Global
	# Pastikan di Inspector Tangga, Target Pos sudah kamu isi angka (bukan 0,0)
	self.global_position = Global.next_spawn_pos
	
	if anim:
		anim.flip_h = Global.next_spawn_flip
	
	# 4. Tunggu 1 frame kecil saja agar engine sadar posisi sudah berubah
	await get_tree().process_frame
	
	# 5. Aktifkan kembali player
	self.visible = true
	set_physics_process(true)
	Global.is_transitioning = false
	print("DEBUG: Player mendarat dengan selamat di: ", global_position)

func _physics_process(delta: float) -> void:
	# Gravitasi sederhana
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# Input gerakan
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
		if anim:
			anim.play("idle")
