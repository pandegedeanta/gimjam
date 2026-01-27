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
