
extends CharacterBody3D

# ==================================================
# MOVEMENT
# ==================================================
@export_group("Movement")

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var crouch_speed: float = 2.5

@export var acceleration: float = 30.0
@export var air_acceleration: float = 8.0
@export var friction: float = 35.0


# ==================================================
# JUMP
# ==================================================
@export_group("Jump")

@export var jump_velocity: float = 5.0
@export var coyote_time: float = 0.15
@export var jump_buffer_time: float = 0.12


# ==================================================
# STAMINA
# ==================================================
@export_group("Stamina")

@export var max_stamina: float = 100.0
@export var sprint_stamina_drain: float = 15.0
@export var slide_stamina_drain: float = 20.0
@export var stamina_regen: float = 20.0
@export var stamina_recovery_delay: float = 1.0

var stamina: float = 100.0
var stamina_recovery_timer: float = 0.0

var is_sprinting: bool = false


# ==================================================
# SLIDE
# ==================================================
@export_group("Slide")

@export var slide_speed: float = 10.0
@export var slide_duration: float = 0.9
@export var slide_deceleration: float = 5.5
@export var slide_min_speed: float = 5.0
@export var slide_cooldown: float = 0.5

var is_sliding: bool = false

var slide_timer: float = 0.0
var slide_cooldown_timer: float = 0.0

var slide_direction: Vector3 = Vector3.ZERO
var current_slide_speed: float = 0.0


# ==================================================
# CAMERA
# ==================================================
@export_group("Camera")

@export var mouse_sensitivity: float = 0.003

@export var normal_fov: float = 75.0
@export var sprint_fov: float = 82.0
@export var slide_fov: float = 86.0

@export var fov_smooth: float = 6.0


# ==================================================
# CROUCH
# ==================================================
@export_group("Crouch")

@export var stand_head_height: float = 1.6
@export var crouch_head_height: float = 1.0

@export var stand_collision_height: float = 1.8
@export var crouch_collision_height: float = 1.1

@export var crouch_smooth: float = 10.0


# ==================================================
# HEAD BOB
# ==================================================
@export_group("Head Bob")

@export var bob_frequency: float = 2.4
@export var bob_amplitude: float = 0.045
@export var bob_smooth: float = 10.0


# ==================================================
# CAMERA SWAY
# ==================================================
@export_group("Camera Sway")

@export var mouse_sway_amount: float = 0.0008
@export var max_mouse_sway: float = 0.04

@export var movement_sway_amount: float = 0.025
@export var sway_smooth: float = 5.0

var mouse_sway: float = 0.0


# ==================================================
# VARIABLES
# ==================================================
var gravity: float = ProjectSettings.get_setting(
    "physics/3d/default_gravity"
)

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

var bob_time: float = 0.0

var camera_default_position: Vector3
var camera_default_rotation: Vector3

var capsule: CapsuleShape3D
var stand_test_capsule: CapsuleShape3D


# ==================================================
# NODE REFERENCES
# ==================================================
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var stamina_bar: ProgressBar = $CanvasLayer/HUD/StaminaBar

# ==================================================
# READY
# ==================================================
func _ready() -> void:

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	stamina = max_stamina
	stamina_bar.max_value = max_stamina
	stamina_bar.value = stamina

	camera_default_position = camera.position
	camera_default_rotation = camera.rotation

	camera.fov = normal_fov

	# Check collision shape
	if collision_shape.shape is not CapsuleShape3D:
		push_error("Player CollisionShape3D must use CapsuleShape3D!")
		set_physics_process(false)
		return

	# Duplicate shape to avoid changing shared resources
	capsule = collision_shape.shape.duplicate() as CapsuleShape3D
	collision_shape.shape = capsule

	capsule.height = stand_collision_height

	stand_test_capsule = CapsuleShape3D.new()
	stand_test_capsule.radius = capsule.radius
	stand_test_capsule.height = stand_collision_height

	# Keep feet at the same position
	collision_shape.position.y = stand_collision_height * 0.5


# ==================================================
# INPUT
# ==================================================
func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:

			rotate_y(-event.relative.x * mouse_sensitivity)

			head.rotate_x(-event.relative.y * mouse_sensitivity)

			head.rotation.x = clampf(
				head.rotation.x,
				deg_to_rad(-89.0),
				deg_to_rad(89.0)
			)

			# Mouse sway
			mouse_sway = clampf(
				mouse_sway - event.relative.x * mouse_sway_amount,
				-max_mouse_sway,
				max_mouse_sway
			)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ==================================================
# PHYSICS PROCESS
# ==================================================
func _physics_process(delta: float) -> void:

	_update_timers(delta)

	_apply_gravity(delta)

	_handle_jump()

	_update_stamina(delta)

	_try_start_slide()

	_handle_movement(delta)

	move_and_slide()

	_handle_crouch(delta)

	_handle_camera_effects(delta)


# ==================================================
# TIMERS
# ==================================================
func _update_timers(delta: float) -> void:

	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = maxf(
			jump_buffer_timer - delta,
			0.0
		)

	slide_cooldown_timer = maxf(
		slide_cooldown_timer - delta,
		0.0
	)


# ==================================================
# GRAVITY
# ==================================================
func _apply_gravity(delta: float) -> void:

	if not is_on_floor():
		velocity.y -= gravity * delta


# ==================================================
# JUMP
# ==================================================
func _handle_jump() -> void:

	if is_sliding:
		return

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:

		velocity.y = jump_velocity

		coyote_timer = 0.0
		jump_buffer_timer = 0.0


# ==================================================
# STAMINA
# ==================================================
func _update_stamina(delta: float) -> void:

	is_sprinting = (
		Input.is_action_pressed("sprint")
		and stamina > 0.0
		and is_on_floor()
		and not Input.is_action_pressed("crouch")
		and not is_sliding
	)

	if is_sliding:

		stamina -= slide_stamina_drain * delta

		stamina_recovery_timer = stamina_recovery_delay

	elif is_sprinting:

		stamina -= sprint_stamina_drain * delta

		stamina_recovery_timer = stamina_recovery_delay

	else:

		stamina_recovery_timer = maxf(
			stamina_recovery_timer - delta,
			0.0
		)

		if stamina_recovery_timer <= 0.0:
			stamina += stamina_regen * delta

	stamina = clampf(stamina, 0.0, max_stamina)
	stamina_bar.value = stamina


# ==================================================
# SLIDE
# ==================================================
func _try_start_slide() -> void:

	if not Input.is_action_just_pressed("crouch"):
		return

	if not Input.is_action_pressed("sprint"):
		return

	if not is_on_floor() or is_sliding:
		return

	if slide_cooldown_timer > 0.0:
		return

	if stamina < 5.0:
		return

	var horizontal_velocity := Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	if horizontal_velocity.length() < slide_min_speed:
		return

	is_sliding = true

	slide_timer = slide_duration

	slide_direction = horizontal_velocity.normalized()

	current_slide_speed = minf(
		horizontal_velocity.length(),
		slide_speed
	)

	# Prevent buffered jump after slide
	jump_buffer_timer = 0.0

	stamina_recovery_timer = stamina_recovery_delay


func _handle_slide(delta: float) -> void:

	slide_timer -= delta

	current_slide_speed = move_toward(
		current_slide_speed,
		0.0,
		slide_deceleration * delta
	)

	var horizontal := slide_direction * current_slide_speed

	velocity.x = horizontal.x
	velocity.z = horizontal.z

	if slide_timer <= 0.0 or current_slide_speed < 1.0:

		is_sliding = false

		slide_cooldown_timer = slide_cooldown


# ==================================================
# SPEED
# ==================================================
func _get_current_speed() -> float:

	if Input.is_action_pressed("crouch"):
		return crouch_speed

	if is_sprinting:
		return sprint_speed

	return walk_speed


# ==================================================
# MOVEMENT
# ==================================================
func _handle_movement(delta: float) -> void:

	if is_sliding:

		_handle_slide(delta)
		return

	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
        "move_back"
	)

	var direction := (
		transform.basis *
		Vector3(input_dir.x, 0.0, input_dir.y)
	).normalized()

	var horizontal := Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	var target_velocity := direction * _get_current_speed()

	if direction.length_squared() > 0.0:

		var accel := (
			acceleration
			if is_on_floor()
			else air_acceleration
		)

		horizontal = horizontal.move_toward(
			target_velocity,
			accel * delta
		)

	elif is_on_floor():

		horizontal = horizontal.move_toward(
			Vector3.ZERO,
			friction * delta
		)

	velocity.x = horizontal.x
	velocity.z = horizontal.z


# ==================================================
# STAND CHECK
# ==================================================
func _can_stand() -> bool:

	if capsule == null:
		return true

	if capsule.height >= stand_collision_height - 0.02:
		return true

	var query := PhysicsShapeQueryParameters3D.new()

	query.shape = stand_test_capsule

	# Lift slightly to avoid detecting the floor
	query.transform = global_transform * Transform3D(
		Basis(),
		Vector3(0.0, stand_collision_height * 0.5 + 0.02, 0.0)
	)

	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	query.margin = 0.001
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var space_state := get_world_3d().direct_space_state

	return space_state.intersect_shape(query, 8).is_empty()


# ==================================================
# CROUCH
# ==================================================
func _handle_crouch(delta: float) -> void:

	var wants_crouch := (
		Input.is_action_pressed("crouch")
		or is_sliding
	)

	if not wants_crouch and not _can_stand():
		wants_crouch = true

	var target_head_height := (
		crouch_head_height
		if wants_crouch
		else stand_head_height
	)

	head.position.y = lerpf(
		head.position.y,
		target_head_height,
		minf(crouch_smooth * delta, 1.0)
	)

	if capsule != null:

		var target_collision_height := (
			crouch_collision_height
			if wants_crouch
			else stand_collision_height
		)

		capsule.height = lerpf(
			capsule.height,
			target_collision_height,
			minf(crouch_smooth * delta, 1.0)
		)

		collision_shape.position.y = capsule.height * 0.5


# ==================================================
# CAMERA EFFECTS
# ==================================================
func _handle_camera_effects(delta: float) -> void:

	var horizontal_speed := Vector2(
		velocity.x,
		velocity.z
	).length()

	var is_moving := horizontal_speed > 0.5

	# HEAD BOB
	var target_bob := Vector3.ZERO

	if is_on_floor() and is_moving:

		var speed_factor := horizontal_speed / walk_speed

		var amplitude := bob_amplitude

		if is_sliding:
			amplitude *= 0.3
		elif Input.is_action_pressed("crouch"):
			amplitude *= 0.5

		bob_time += delta * bob_frequency * speed_factor

		target_bob.y = sin(bob_time) * amplitude

		target_bob.x = cos(bob_time * 0.5) * amplitude * 0.5

	camera.position = camera.position.lerp(
		camera_default_position + target_bob,
		minf(bob_smooth * delta, 1.0)
	)

	# CAMERA SWAY
	mouse_sway = lerpf(
		mouse_sway,
		0.0,
		minf(sway_smooth * delta, 1.0)
	)

	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
        "move_back"
	)

	var target_rotation := camera_default_rotation

	target_rotation.z = (
		camera_default_rotation.z
		- input_dir.x * movement_sway_amount
		+ mouse_sway
	)

	target_rotation.y = (
		camera_default_rotation.y
		+ mouse_sway * 0.5
	)

	camera.rotation = camera.rotation.lerp(
		target_rotation,
		minf(sway_smooth * delta, 1.0)
	)

	# DYNAMIC FOV
	var target_fov := normal_fov

	if is_sliding:
		target_fov = slide_fov
	elif is_sprinting:
		target_fov = sprint_fov

	camera.fov = lerpf(
		camera.fov,
		target_fov,
		minf(fov_smooth * delta, 1.0)
	)
