extends CharacterBody3D

#region Variables
# Mouse / Look
var look_rotation: Vector2
var look_speed: float = 0.002
var mouse_captured: bool = false

# Movement
var accel: float = GROUND_ACCEL
var direction: Vector3 = Vector3.ZERO
var speed: float = WALK_SPEED
var floor_grace_time: float = 0.1
var floor_timer: float = 0.0

# Jump buffering
var jump_buffer_time: float = 0.1
var jump_buffer_timer: float = 0.0

# Slide
var slide_dir: Vector3 = Vector3.ZERO
var slide_timer: float = 0.0

# State
var current_state: States = States.FALL
var previous_state: States = States.WALK
var state_change_cooldown: float = 0.1
#endregion

#region Constants
# Movement
const AIR_ACCEL: float = 2.0
const CROUCH_HEIGHT: float = 0.8
const CROUCH_SPEED: float = 2.0
const GROUND_ACCEL: float = 10.0
const JUMP_VELOCITY: float = 4.5
const NORMAL_HEIGHT: float = 2.0
const SPRINT_SPEED: float = 7.0
const WALK_SPEED: float = 3.0

# Camera
const NORMAL_CAMERA_Y: float = -0.5
const NORMAL_FOV: float = 80.0
const SLIDE_CAMERA_Y: float = -0.7
const SLIDE_FOV: float = 93.5
const SPRINT_FOV: float = 85.0

# Slide
const SLIDE_BOOST: float = 12.0
const SLIDE_FRICTION: float = 10.0
const SLIDE_TIME: float = 0.7
const SLIDE_MIN_SPEED: float = 5.0
#endregion

#region Onready Vars
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var collider_capsule: CapsuleShape3D = $Collider.shape
@onready var camera_3d: Camera3D = $Head/Camera3D
@onready var headroom_checker: ShapeCast3D = $Head/Headroom_checker
#endregion

enum States {
	JUMP,
	WALK,
	FALL,
	CROUCH,
	SPRINT,
	SLIDE
}

func _ready() -> void:
	headroom_checker.add_exception(self)

func _physics_process(delta: float) -> void:
	# --- TIMERS ---
	state_change_cooldown -= delta
	
	# --- INPUT ---
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# --- UPDATE FLOOR TIMER (Coyote Time) ---
	if is_on_floor():
		floor_timer = floor_grace_time	# reset when on floor
	else:
		floor_timer -= delta	# countdown while in air

	# --- UPDATE JUMP BUFFER ---
	if Input.is_action_just_pressed("Jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	# --- STATE TRANSITIONS ---
	var on_floor_or_coyote := floor_timer > 0.0
	
	if on_floor_or_coyote:
		accel = GROUND_ACCEL

		# Jump input (with buffering and coyote time)
		if jump_buffer_timer > 0.0 and can_stand():
			jump_buffer_timer = 0.0  # consume the buffer
			previous_state = current_state
			change_state(States.JUMP)

		# Crouch / Slide input
		if Input.is_action_just_pressed("Crouch"):
			if current_state == States.SPRINT:
				previous_state = current_state
				change_state(States.SLIDE)
			else:
				previous_state = current_state
				change_state(
					States.WALK if current_state == States.CROUCH and can_stand() else States.CROUCH
				)

		# Sprint toggle
		if Input.is_action_just_pressed("Sprint"):
			if current_state == States.CROUCH and can_stand():
				# Allow sprint from crouch if we can stand
				previous_state = current_state
				change_state(States.SPRINT)
			elif current_state != States.CROUCH and current_state != States.SLIDE:
				# Normal sprint toggle for other states
				previous_state = current_state
				change_state(
					States.WALK if current_state == States.SPRINT else States.SPRINT
				)
	else:
		# In air (after coyote time expires)
		accel = AIR_ACCEL
		if current_state not in [States.FALL, States.JUMP, States.SLIDE, States.SPRINT, States.WALK]:
			previous_state = current_state
			change_state(States.FALL)

	# --- HORIZONTAL MOVEMENT ---
	if current_state != States.SLIDE:
		var target_vel := direction * speed
		velocity.x = move_toward(velocity.x, target_vel.x, accel)
		velocity.z = move_toward(velocity.z, target_vel.z, accel)

	# --- APPLY GRAVITY (for all airborne states) ---
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	# --- STATE LOGIC ---
	match current_state:
		States.JUMP:
			# Jump impulse applied once, then transition
			velocity.y = JUMP_VELOCITY
			
			# If we jumped from a slide or crouch, go to sprint/walk (stand up in air) instead of fall
			if previous_state == States.SLIDE:
				previous_state = States.SPRINT  # Update so landing knows we're sprinting
				change_state(States.SPRINT)
			elif previous_state == States.CROUCH:
				previous_state = States.WALK  # Update so landing knows we're walking
				change_state(States.WALK)
			else:
				change_state(States.FALL)

		States.SLIDE:
			slide_timer -= delta
			update_collider(delta)

			# Slide pushes forward with proper friction
			var slide_vel := slide_dir * SLIDE_BOOST
			velocity.x = move_toward(velocity.x, slide_vel.x, SLIDE_FRICTION)
			velocity.z = move_toward(velocity.z, slide_vel.z, SLIDE_FRICTION)

			# End slide if time runs out, airborne, or too slow
			var current_speed := Vector3(velocity.x, 0, velocity.z).length()
			if slide_timer <= 0.0 or floor_timer <= 0.0 or current_speed < SLIDE_MIN_SPEED:
				previous_state = current_state
				change_state(States.CROUCH)

		States.FALL:
			# Landing: restore previous state when back on actual floor
			if is_on_floor():
				var landing_state = States.WALK  # default fallback
				
				# Preserve sprint/walk/crouch if that's what we were doing
				if previous_state in [States.SPRINT, States.WALK, States.CROUCH]:
					landing_state = previous_state
				
				change_state(landing_state)

		States.SPRINT:
			update_collider(delta)
			
			# Auto-downgrade to walk if not moving (but only on ground and not during jump buffer)
			if direction.length() < 0.1 and is_on_floor() and jump_buffer_timer <= 0.0:
				previous_state = current_state
				change_state(States.WALK)

		States.WALK, States.CROUCH:
			update_collider(delta)

	# --- PHYSICS ---
	move_and_slide()

	# --- CAMERA ---
	update_camera_height(delta)
	update_fov(delta)


func update_collider(delta):
	var target := NORMAL_HEIGHT
	if current_state == States.CROUCH or current_state == States.SLIDE:
		target = CROUCH_HEIGHT

	collider_capsule.height = lerp(
		collider_capsule.height,
		target,
		8.0 * delta
	)

func update_fov(delta):
	var target_fov := NORMAL_FOV

	match current_state:
		States.SLIDE:
			target_fov = SLIDE_FOV
		States.SPRINT:
			target_fov = SPRINT_FOV
		_:
			target_fov = NORMAL_FOV

	camera_3d.fov = lerp(
		camera_3d.fov,
		target_fov,
		8.0 * delta
	)
	
func update_camera_height(delta):
	var target_y := NORMAL_CAMERA_Y

	if current_state == States.SLIDE:
		target_y = SLIDE_CAMERA_Y
	elif current_state == States.CROUCH:
		target_y = SLIDE_CAMERA_Y + 0.2

	camera_3d.position.y = lerp(
		camera_3d.position.y,
		target_y,
		10.0 * delta
	)

func change_state(new_state: States) -> void:
	# Prevent rapid state spam (except for immediate transitions like JUMP->FALL/SPRINT/WALK)
	if state_change_cooldown > 0.0 and new_state not in [States.FALL, States.SPRINT, States.WALK]:
		return
	
	state_change_cooldown = 0.05  # 50ms cooldown
	current_state = new_state
	
	match new_state:
		States.WALK:
			speed = WALK_SPEED
		States.CROUCH:
			speed = CROUCH_SPEED
		States.SPRINT:
			speed = SPRINT_SPEED
		States.SLIDE:
			slide_timer = SLIDE_TIME
			slide_dir = Vector3(velocity.x, 0, velocity.z).normalized()
			if slide_dir == Vector3.ZERO:
				slide_dir = -transform.basis.z

func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)

func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func can_stand() -> bool:
	return !headroom_checker.is_colliding()

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false
