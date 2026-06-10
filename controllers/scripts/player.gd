extends CharacterBody3D


@export var SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var MOUSE_SENSITIVITY : float
@export var 	CAM_VERT_LOWER_LIMIT := deg_to_rad(-90)
@export var 	CAM_VERT_UPPER_LIMIT := deg_to_rad(90)
@export var 	CAM_CONTROLLER : Camera3D

var _mouse_input : bool = false
var _mouse_rotation : Vector3
var _mouse_horizontal : float
var _mouse_vertical : float
var _player_rotation : Vector3
var _camera_rotation : Vector3
var mouse_locked: bool = false

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	$MultiplayerSynchronizer.set_multiplayer_authority(name.to_int())

func _input(event):
	if event.is_action_pressed("exit"):
		get_tree().quit()

func _unhandled_input(event):
	
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_mouse_horizontal = -event.relative.x * MOUSE_SENSITIVITY
		_mouse_vertical = -event.relative.y * MOUSE_SENSITIVITY
	#print(Vector2(_mouse_horizontal, _mouse_vertical))
	
func _update_camera(delta):
	_mouse_rotation.x += _mouse_vertical * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, CAM_VERT_LOWER_LIMIT, CAM_VERT_UPPER_LIMIT)
	_mouse_rotation.y += _mouse_horizontal * delta
	
	_player_rotation = Vector3(0.0, _mouse_rotation.y, 0.0)
	_camera_rotation = Vector3(_mouse_rotation.x, 0.0, 0.0)
	
	CAM_CONTROLLER.rotation = _camera_rotation
	CAM_CONTROLLER.rotation.z = 0.0
	
	rotation = _player_rotation
	
	_mouse_horizontal = 0.0
	_mouse_vertical = 0.0



func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	CAM_CONTROLLER.current = is_multiplayer_authority()
	print("My peer ID: ", multiplayer.get_unique_id())
	print("My node name: ", name)
	print("Am I authority: ", is_multiplayer_authority())
	print("CAM_CONTROLLER: ", CAM_CONTROLLER)
	print("Is current: ", CAM_CONTROLLER.current)

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return

	if Input.is_action_just_pressed("tab"):
		toggle_mouse_mode()

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	_update_camera(delta)

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if Input.is_action_pressed("sprint"):
		SPEED = 7
	else:
		SPEED = 5
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func toggle_mouse_mode():
	mouse_locked = !mouse_locked

	if mouse_locked:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif !mouse_locked:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE