extends ColorRect


func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		get_parent().close_code_panel()
