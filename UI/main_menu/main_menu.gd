extends Control

func _ready() -> void:
	# คืนค่าเมาส์ให้มองเห็นและกดเมนูได้
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func _on_playgame_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/loading/loading_screen.tscn")


func _on_quit_pressed() -> void:
	pass
	get_tree().quit()
