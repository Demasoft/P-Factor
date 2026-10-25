extends Label

signal cursor_selected()

func cursor_select() -> void:
	print(name)
	emit_signal("cursor_selected") 
