extends Control

func _ready() -> void:
	# คืนค่าเมาส์ให้มองเห็นและกดเมนูได้
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func _on_playgame_pressed() -> void:
	pass
	get_tree().change_scene_to_file("res://world.tscn")


func _on_quit_pressed() -> void:
	pass
	get_tree().quit()
