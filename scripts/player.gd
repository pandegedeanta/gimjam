extends CharacterBody2D

@export var speed := 300.0
@onready var anim := $AnimatedSprite2D

var is_transitioning := false # Saklar untuk mematikan kontrol

func _physics_process(delta: float) -> void:
	if is_transitioning:
		return # Berhenti memproses input jika sedang transisi

	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction := Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		velocity.x = direction * speed
		anim.play("walk")
		anim.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		anim.play("idle")

	move_and_slide()
var camera_tween: Tween

func lock_camera(left: int, right: int, smooth: bool = true):
	var cam = $Camera2D
	if not cam: return
	
	if camera_tween: camera_tween.kill()
	
	if smooth:
		# 1. MATIKAN smoothing segera agar tidak ada delay kalkulasi
		cam.position_smoothing_enabled = false
		
		# 2. Tween limit secara halus
		camera_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		camera_tween.tween_property(cam, "limit_left", left, 2.0) # Sesuaikan durasi rekamanmu
		camera_tween.tween_property(cam, "limit_right", right, 2.0)
		
		# 3. Paksa kamera update posisinya di setiap frame selama transisi
		camera_tween.chain().tween_callback(func(): 
			cam.position_smoothing_enabled = true
			cam.force_update_scroll() # Paksa refresh!
		)
	else:
		cam.limit_left = left
		cam.limit_right = right
		cam.force_update_scroll()

func unlock_camera_limits(full_left: int, full_right: int):
	var cam = $Camera2D
	if not cam: return
	
	if camera_tween: camera_tween.kill()
	
	cam.position_smoothing_enabled = false
	
	camera_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(cam, "limit_left", full_left, 2.0)
	camera_tween.tween_property(cam, "limit_right", full_right, 2.0)
	
	camera_tween.chain().tween_callback(func(): 
		cam.position_smoothing_enabled = true
		cam.force_update_scroll()
	)
