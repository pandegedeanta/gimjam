extends CharacterBody2D

@export var ui_node: CanvasLayer
@export var speed := 300.0
@onready var anim := $AnimatedSprite2D

var is_transitioning := false # Saklar untuk mematikan kontrol
# Variabel buat mekanik sembunyi 
var is_hidden := false
var can_move := true
var current_wardrobe: Node2D = null

func _ready():
	print("PARENT:", get_parent().name)
	print("PARENT ALPHA:", get_parent().modulate.a)

func hide_in_wardrobe(wardrobe: Node2D):
	is_hidden = true
	can_move = false
	current_wardrobe = wardrobe

	# Posisikan ke lemari (opsional)
	global_position = wardrobe.global_position

	# HILANGKAN PLAYER TOTAL
	visible = false
	$CollisionShape2D.disabled = true

	if ui_node:
		ui_node.show_exit_hint()


func unhide_from_wardrobe():
	if not current_wardrobe:
		return

	is_hidden = false
	can_move = true

	reparent(get_tree().current_scene)
	z_index = 0
	visible = true
	$CollisionShape2D.disabled = false

	global_position = Vector2(-230, 200)

	if ui_node:
		ui_node.hide_exit_hint()

	current_wardrobe = null

func _input(event):
	if not is_hidden:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		exit_wardrobe()

func exit_wardrobe():
	if not current_wardrobe:
		return

	var wardrobe := current_wardrobe

	# Geser player keluar lemari (kanan/kiri)
	global_position = wardrobe.global_position + Vector2(48, 0)

	wardrobe.force_exit()


func _physics_process(delta: float) -> void:
	if not can_move:
		return

	# movement normal di bawah sini
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
	
	if is_hidden:
		print("PLAYER HIDDEN | alpha:", modulate.a)

func _on_wardrobe_player_hide_requested(wardrobe: Node2D) -> void:
	hide_in_wardrobe(wardrobe)

func _on_wardrobe_player_unhide_requested(wardrobe: Node2D) -> void:
	unhide_from_wardrobe()
