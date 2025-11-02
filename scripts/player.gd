extends CharacterBody3D

#variables and constants
const WALK_SPEED = 7.0
const SPRINT_SPEED = 11.0
const JUMP_VELOCITY = 8
const SENSITIVITY = 0.003
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5
#------------------------------------------------------
var speed
var t_bob = 0.0
var gravity = 20
# Debug variables for teleportation detection
var last_position = Vector3.ZERO
var teleport_threshold = 2.0  # If player moves more than this distance in one frame, it's likely a teleport
var safe_move_distance = 15.0  # Maximum reasonable move distance per frame
#------------------------------------------------------
@onready var head = $Head
@onready var camera = $Head/playerCamera

#function on startup
func _ready():
	#detects mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	last_position = global_position

#camera function
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(90))

#movement function
func _physics_process(delta):
	# Debug: Check for unexpected position changes (teleportation)
	var distance_moved = global_position.distance_to(last_position)
	if distance_moved > teleport_threshold:
		print("POSSIBLE TELEPORT DETECTED!")
		print("Previous position: ", last_position)
		print("Current position: ", global_position)
		print("Distance moved: ", distance_moved)
		print("Frame velocity: ", velocity)
		print("Is on floor: ", is_on_floor())
		
		# Try to prevent unwanted teleportation by restoring previous position
		# Only if the movement seems unrealistic
		if distance_moved > safe_move_distance and velocity.length() < 20.0:
			print("REVERTING TELEPORT - restoring previous position")
			global_position = last_position
			velocity = Vector3.ZERO
		print("---")
	
	if not is_on_floor():
		velocity.y -= gravity * delta
#------------------------------------------------------
#jump input
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
#------------------------------------------------------
#sprint input
	if Input.is_action_pressed("shift"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
#------------------------------------------------------
#wasd direction input and other physics
	var input_dir = Input.get_vector("a", "d", "w", "s")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)
#------------------------------------------------------
#headbob during movement
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
#------------------------------------------------------
#fov changing
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	move_and_slide()
	
	# Update last position for teleport detection
	last_position = global_position

#function for head bob
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

# Debug function to check collision state
func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key - toggle mouse mode for debugging
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event.is_action_pressed("space"):  # Space key - print debug info
		print("=== PLAYER DEBUG INFO ===")
		print("Position: ", global_position)
		print("Velocity: ", velocity)
		print("Is on floor: ", is_on_floor())
		print("Floor normal: ", get_floor_normal())
		print("Wall normal: ", get_wall_normal())
		print("Slide collision count: ", get_slide_collision_count())
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			print("Collision ", i, ": ", collision.get_collider(), " at ", collision.get_position())
