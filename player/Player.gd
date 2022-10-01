class_name Player
extends KinematicBody

enum PlayerState {
	Walking,
	Crouching
}

export (float) var gravity = -34.8
export (float) var max_walk_speed = 8.0
export (float) var max_crouch_speed = 3.0
export (float) var jump_speed  = 12.0
export (float) var acceleration = 1.0
export (float) var deceleration = 5.0
export (float) var max_slope_angle = 90.0
export (float) var mouse_sensitivity = 0.4
export (float) var crouch_amount = 0.5
export (float) var walk_footstep_delay = 0.5

export (float) var min_visisibility_cutoff = 10.0
export (float) var max_visisibility_cutoff = 220.0

onready var body : CollisionShape = $Body
onready var head : Spatial = $Head
onready var camera : Camera = $Head/Pivot/Camera
onready var pivot : Spatial = $Head/Pivot
onready var visi_viewport : Viewport = $ViewportContainer/Viewport
onready var visi_cam : Camera = $ViewportContainer/Viewport/VisibilityCamera
onready var visi_timer : Timer = $VisibilityTimer
onready var normal_body_height : float = body.shape.height
onready var normal_body_radius : float = body.shape.radius
onready var normal_body_offset : float = body.transform.origin.y
onready var normal_head_height : float = head.transform.origin.y


# UI
onready var visi_bar : ProgressBar = $UI/Visibility
onready var overlay : ColorRect = $UI/Overlay
onready var pause_screen : Control = $UI/PauseScreen
onready var resume_button : Button = $UI/PauseScreen/VBoxContainer/ResumeButton
onready var quit_button : Button = $UI/PauseScreen/VBoxContainer/QuitButton
onready var paused_text_screen : Control = $UI/PausedTextScreen
onready var paused_text_resume_button : Button = $UI/PausedTextScreen/VBoxContainer/ResumeButton
onready var paused_text : Label = $UI/PausedTextScreen/VBoxContainer/Label
onready var overlay_text : Control = $UI/OverlayText
onready var overlay_text_label : Label = $UI/OverlayText/Label
onready var overlay_text_timer : Timer = $OverlayTextTimer

var state = PlayerState.Walking
var dir := Vector3()
var vel := Vector3()
var visibility := 0.0
var footstep_countdown := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	visi_timer.connect("timeout", self, "_update_visibility")
	resume_button.connect("pressed", self, "_toggle_pause")
	paused_text_resume_button.connect("pressed", self, "_toggle_pause")
	overlay_text_timer.connect("timeout", self, "_hide_overlay_text")
	quit_button.connect("pressed", self, "_quit")
	_update_visibility()

func _update_visibility():
	var visi_img = visi_viewport.get_texture().get_data()
	visi_img.lock()

	var raw_pix = visi_img.get_data()
	var total = 0.0

	for pix in raw_pix:
		total += pix

	var raw_vis = total / (raw_pix.size())
	var clamped_vis = clamp(raw_vis, min_visisibility_cutoff, max_visisibility_cutoff)
	visibility = clamped_vis / (max_visisibility_cutoff - min_visisibility_cutoff)
	visi_bar.value = visibility

func _physics_process(delta):
	_process_input(delta)
	if not GameState.paused:
		_process_movement(delta)
		_do_footsteps(delta)
		if state == PlayerState.Crouching:
			_do_crouch()

func _do_crouch():
	var rate_of_change = 0.1
	var from
	var to

	from = body.shape.height
	to = normal_body_height * crouch_amount
	body.shape.height = lerp(from, to, rate_of_change)

	from = body.shape.radius
	to = normal_body_radius * crouch_amount
	body.shape.radius = lerp(from, to, rate_of_change)

	from = body.transform.origin.y
	to = normal_body_offset * crouch_amount
	body.transform.origin.y = lerp(from, to, rate_of_change)

	from = head.transform.origin.y
	to = normal_head_height * crouch_amount
	head.transform.origin.y = lerp(from, to, rate_of_change)

func _undo_crouch():
	state = PlayerState.Walking
	body.shape.height = normal_body_height
	body.shape.radius = normal_body_radius
	body.transform.origin.y = normal_body_offset
	head.transform.origin.y = normal_head_height

func _do_footsteps(delta):
	if is_on_floor() and vel.length() > 0.0:
		if footstep_countdown == 0.0:
			pass
			# print("FOOTSTEP")

		footstep_countdown += delta
		if footstep_countdown >= walk_footstep_delay:
			footstep_countdown = 0.0

	else:
		footstep_countdown = 0.0

func _process_input(_delta):

	if not GameState.paused:
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

		if Input.is_action_just_pressed("crouch"):
			if state == PlayerState.Walking:
				state = PlayerState.Crouching
			elif state == PlayerState.Crouching:
				_undo_crouch()

	if Input.is_action_just_pressed("ui_cancel"):
		_toggle_pause()

func _toggle_pause():
	if GameState.paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		overlay.visible = false
		pause_screen.visible = false
		paused_text_screen.visible = false
		GameState.paused = false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		overlay.visible = true
		pause_screen.visible = true
		GameState.paused = true

func _process_movement(delta):
	dir.y = 0
	dir = dir.normalized()

	vel.y += delta * gravity

	var hvel = vel
	hvel.y = 0

	var target = dir

	var max_speed = max_walk_speed
	if state == PlayerState.Crouching:
		max_speed = max_crouch_speed

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

	visi_cam.global_transform.origin = Vector3(global_transform.origin.x, visi_cam.global_transform.origin.y, global_transform.origin.z)

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		pivot.rotate_x(-1 * deg2rad(event.relative.y * mouse_sensitivity))
		self.rotate_y(deg2rad(event.relative.x * mouse_sensitivity * -1))

		var camera_rot = pivot.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		pivot.rotation_degrees = camera_rot

func _hide_overlay_text():
	overlay_text.visible = false

func _quit():
	var scene = load("res://Title.tscn")
	get_tree().change_scene_to(scene)

func trigger_paused_text(text):
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	paused_text.text = text
	overlay.visible = true
	paused_text_screen.visible = true
	GameState.paused = true

func trigger_overlay_text(text):
	overlay_text_label.text = text
	overlay_text.visible = true
	overlay_text_timer.start()

func die():
	GameState.escaped = false
	var end_screen = load("res://End.tscn")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to(end_screen)
