extends Area

const end_screen = preload("res://End.tscn")

func _ready():
	connect("body_entered", self, "_trigger_escape")

func _trigger_escape(body):
	if body is Player:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GameState.escaped = true
		get_tree().change_scene_to(end_screen)
