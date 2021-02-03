extends MarginContainer

signal pressed()

#why do I need to use a custom signal for this? why can't I just connect to the button's signal instead?
func _on_Button_pressed():
	emit_signal("pressed")
