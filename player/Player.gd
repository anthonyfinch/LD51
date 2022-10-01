extends KinematicBody


export (float) var gravity = -34.8
export (float) var max_speed = 8.0
export (float) var jump_speed  = 12.0
export (float) var acceleration = 1.0
export (float) var deceleration = 5.0
export (float) var max_slope_angle = 90.0
export (float) var mouse_sensitivity = 0.4

onready var camera = $Head/Pivot/Camera
onready var pivot = $Head/Pivot

var dir = Vector3()
var vel = Vector3()


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	process_input(delta)
	process_movement(delta)


func process_input(_delta):

	dir = Vector3()
	var cam_xform = camera.get_global_transform()

	var input_movement_vector = Vector2()

	if Input.is_action_pressed("forward"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("back"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("right"):
		input_movement_vector.x += 1

	input_movement_vector = input_movement_vector.normalized()

	dir += -cam_xform.basis.z * input_movement_vector.y
	dir += cam_xform.basis.x * input_movement_vector.x

	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			vel.y = jump_speed

	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()

	vel.y += delta * gravity

	var hvel = vel
	hvel.y = 0

	var target = dir

	target *= max_speed

	var accel
	if dir.dot(hvel) > 0:
		accel = acceleration
	else:
		accel = deceleration

	hvel = hvel.linear_interpolate(target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	vel = move_and_slide(vel, Vector3(0, 1, 0), 1.0, 4, deg2rad(max_slope_angle))

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		pivot.rotate_x(-1 * deg2rad(event.relative.y * mouse_sensitivity))
		self.rotate_y(deg2rad(event.relative.x * mouse_sensitivity * -1))

		var camera_rot = pivot.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		pivot.rotation_degrees = camera_rot
