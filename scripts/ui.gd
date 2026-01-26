extends CanvasLayer

signal overlay_closed
signal code_entered(code: String)

# Pastikan Path ini sesuai dengan Scene Tree kamu!
@onready var item_display = $ItemDisplay
@onready var code_input = $CodeInput
@onready var line_edit = $CodeInput/Background/LineEdit 

func _ready():
	hide()
	if code_input: code_input.hide()
	print("UI System: Ready. Node LineEdit: ", "Ketemu" if line_edit else "HILANG!")

func show_item(texture_to_show: Texture2D):
	if code_input: code_input.hide()
	item_display.show()
	item_display.texture = texture_to_show
	show()

func show_code_input():
	get_tree().paused = true # Bekukan Player
	item_display.hide()
	if code_input:
		code_input.show()
		line_edit.text = ""
		line_edit.grab_focus()
	show()
	print("UI System: Panel Kode Terbuka")

func _input(event):
	if not visible or (code_input and code_input.visible): return
	
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
		hide()
		emit_signal("overlay_closed")

# HUBUNGKAN signal 'pressed' dari EnterButton ke sini via Editor (Tab Node)
func _on_enter_pressed(_extra_arg = ""):
	var teks = line_edit.text.strip_edges()
	print("UI System: Mengirim kode ke laci -> ", teks)
	
	# Emit sinyal duluan sebelum tutup agar 'await' di laci terbangun
	code_entered.emit(teks) 
	
	if code_input: code_input.hide()
	hide()
	get_tree().paused = false


func _on_enter_button_pressed() -> void:
	pass # Replace with function body.
