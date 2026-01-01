extends CharacterBody3D

@export var speed := 4.0
@export var jump_velocity := 4.5
@export var gravity := 9.81
@export var mouse_sens := 0.1
@export var slide_pitch := -25
@export var friction_default := 8.0
@export var friction_slide := 0.1
@export var fov_min := 90
@export var fov_max := 120
var run_speed = 10.0
var yaw := 0.0
var pitch := 0.0
var cam_pitch := 0.0
var slide_offset := -0.6
var bob_amount := 0.05
var bob_speed := 8.0
var bob_timer := 0.0
@onready var cam := $Camera3D
@onready var collision = $CollisionShape3D
var default_y = 0.5
func _ready():
	
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam_pitch = cam.rotation_degrees.x

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sens
		pitch -= event.relative.y * mouse_sens
		pitch = clamp(pitch, -90, 90)
		rotation_degrees.y = yaw

func _physics_process(delta):
	# --- input ---
	var input_dir := Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		input_dir -= transform.basis.z
	if Input.is_action_pressed("move_back"):
		input_dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		input_dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		input_dir += transform.basis.x
	if Input.is_action_pressed("run"):
		speed = lerp(speed,run_speed,delta)
		
	input_dir = input_dir.normalized()

	# movement with friction and headbob
	var target_vel := input_dir * speed
	var friction := friction_default
	if Input.is_action_pressed("slide"):
		friction = friction_slide
	
	if velocity.length() > 1: 
			bob_timer += delta * bob_speed
			cam.position.y = default_y + sin(bob_timer) * bob_amount
	else:
			
			cam.position.y = lerp(cam.position.y, default_y, delta * 8)
	velocity.x = lerp(velocity.x, target_vel.x, delta * friction)
	velocity.z = lerp(velocity.z, target_vel.z, delta * friction)
	
	# jump
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	

	# gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()

	# --- camera + slide ---
	var slide := Input.is_action_pressed("slide")
	var target_pitch := pitch
	if slide:
		cam.position.y = lerp(cam.position.y, default_y + slide_offset, delta * 8)
		collision.scale.y = lerp(cam.position.y, default_y + slide_offset, delta * 8)
	else:
		cam.position.y = lerp(cam.position.y, default_y, delta * 8)
		collision.scale.y = lerp(cam.position.y, default_y, delta * 8)


		target_pitch += slide_pitch

	cam_pitch = lerp(cam_pitch, target_pitch, 8 * delta)
	cam.rotation_degrees.x = cam_pitch
	
	# --- Velocity-based FOV ---
	var speed_ratio := velocity.length() / speed
	speed_ratio = clamp(speed_ratio, 0, 1)
	cam.fov = lerp(fov_min, fov_max, speed_ratio)
