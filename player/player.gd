extends CharacterBody3D

# ---------- ความเร็ว ----------
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var crouch_speed: float = 2.5
@export var acceleration: float = 40.0
@export var air_acceleration: float = 10.0
@export var friction: float = 50.0

# ---------- กระโดด ----------
@export var jump_velocity: float = 5.0
@export var coyote_time: float = 0.1

# ---------- กล้อง ----------
@export var mouse_sensitivity: float = 0.003
@export var normal_fov: float = 75.0
@export var sprint_fov: float = 85.0

# ---------- ย่อตัว ----------
@export var stand_head_height: float = 1.6
@export var crouch_head_height: float = 1.0

# ---------- Head Bob (กล้องโยกตอนเดิน) ----------
@export var bob_frequency: float = 2.4
@export var bob_amplitude: float = 0.06

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var coyote_timer: float = 0.0
var bob_time: float = 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED   # ซ่อนและล็อกเมาส์


func _unhandled_input(event: InputEvent) -> void:
	# หมุนมุมมองด้วยเมาส์
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)       # หันทั้งตัว ซ้าย-ขวา
		head.rotate_x(-event.relative.y * mouse_sensitivity)  # ก้ม-เงย เฉพาะหัว
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))

	# Esc = ปล่อยเมาส์, คลิกในเกม = จับเมาส์กลับ
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement(delta)
	move_and_slide()
	_handle_crouch(delta)
	_handle_camera_effects(delta)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
		velocity.y -= gravity * delta


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and coyote_timer > 0.0:
		velocity.y = jump_velocity
		coyote_timer = 0.0


func _get_current_speed() -> float:
	if Input.is_action_pressed("crouch"):
		return crouch_speed
	if Input.is_action_pressed("sprint") and is_on_floor():
		return sprint_speed
	return walk_speed


func _handle_movement(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var target: Vector3 = direction * _get_current_speed()

	if direction != Vector3.ZERO:
		var accel: float = acceleration if is_on_floor() else air_acceleration
		horizontal = horizontal.move_toward(target, accel * delta)
	elif is_on_floor():
		horizontal = horizontal.move_toward(Vector3.ZERO, friction * delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _handle_crouch(delta: float) -> void:
	var target_height: float = crouch_head_height if Input.is_action_pressed("crouch") else stand_head_height
	head.position.y = lerpf(head.position.y, target_height, 10.0 * delta)


func _handle_camera_effects(delta: float) -> void:
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()

	# Head Bob
	if is_on_floor() and horizontal_speed > 0.5:
		bob_time += delta * horizontal_speed
		camera.position.y = sin(bob_time * bob_frequency) * bob_amplitude
		camera.position.x = cos(bob_time * bob_frequency * 0.5) * bob_amplitude
	else:
		camera.position = camera.position.lerp(Vector3.ZERO, 10.0 * delta)

	# FOV กว้างขึ้นตอนวิ่ง
	var is_sprinting: bool = Input.is_action_pressed("sprint") and horizontal_speed > walk_speed
	var target_fov: float = sprint_fov if is_sprinting else normal_fov
	camera.fov = lerpf(camera.fov, target_fov, 8.0 * delta)
