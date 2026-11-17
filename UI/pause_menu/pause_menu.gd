extends Control

func _ready() -> void:
	# ตอนเริ่มเกม ให้ซ่อนเมนูนี้ไว้ก่อน (เผื่อเผลอลืมปิดใน Editor)
	hide()

func _unhandled_input(event: InputEvent) -> void:
	# เช็คว่ากดปุ่ม ESC หรือไม่ (ui_cancel คือปุ่ม ESC ค่าเริ่มต้น)
	if event.is_action_pressed("Esc"):
		# สลับสถานะ เปิด/ปิด เมนู
		if visible:
			resume_game()
		else:
			pause_game()

func pause_game() -> void:
	show() 
	get_tree().paused = true 
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 
	
	# ค้นหา Player จากกลุ่ม แล้วเจาะจงเข้าถึง HUD ผ่าน CanvasLayer ของมัน
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# มองหา CanvasLayer ที่อยู่ใน Player ก่อน แล้วค่อยเข้า HUD
		var canvas_layer = player.get_node_or_null("CanvasLayer")
		if canvas_layer:
			var hud = canvas_layer.get_node_or_null("HUD")
			if hud:
				hud.hide()

func resume_game() -> void:
	hide() 
	get_tree().paused = false 
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var canvas_layer = player.get_node_or_null("CanvasLayer")
		if canvas_layer:
			var hud = canvas_layer.get_node_or_null("HUD")
			if hud:
				hud.show()

# ปุ่ม Resume (กลับไปเล่นต่อ)
func _on_resume_pressed() -> void:
	resume_game()

# ปุ่ม Quit (ออกไปหน้าเมนูหลัก หรือปิดเกม)
func _on_main_menu_pressed() -> void:
	get_tree().paused = false # สำคัญมาก: ต้องปลด Pause ก่อนเปลี่ยนฉาก ไม่งั้นฉากใหม่จะค้าง
	get_tree().change_scene_to_file("res://UI/main_menu/main_menu.tscn")
