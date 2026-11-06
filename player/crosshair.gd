extends Control

@export var dot_radius: float = 3.0        # ขนาดของจุด (ปรับให้ใหญ่ขึ้นได้ตามชอบ)
@export var dot_color: Color = Color.WHITE # สีของจุด

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# วาดจุดกลม ๆ ไว้ที่จุดกึ่งกลาง (0, 0) ของ Control นิ่งๆ แค่จุดเดียว
	draw_circle(Vector2.ZERO, dot_radius, dot_color)
