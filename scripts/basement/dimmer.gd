extends ColorRect

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		var ui = get_parent()
		if ui.dimmer_mode == ui.DimmerMode.OVERLAY_UI:
			ui.close_code_panel()
