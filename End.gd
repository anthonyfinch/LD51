extends Control

onready var success_text = $VBoxContainer/Success
onready var failure_text = $VBoxContainer/Failure
onready var restart_button = $VBoxContainer/RestartButton
onready var quit_button = $VBoxContainer/QuitButton


func _ready():
	if GameState.escaped:
		failure_text.visible = false
	else:
		success_text.visible = false

	restart_button.connect("pressed", self, "_restart_game")
	quit_button.connect("pressed", self, "_quit")

func _restart_game():
	var title = load("res://Title.tscn")
	get_tree().change_scene_to(title)

func _quit():
	get_tree().quit()
