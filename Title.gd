extends Control

const level = preload("res://levels/TestLevel1.tscn")

onready var start_button = $VBoxContainer/StartButton
onready var quit_button = $VBoxContainer/QuitButton

func _ready():
	start_button.connect("pressed", self, "_start_game")
	quit_button.connect("pressed", self, "_quit")

func _start_game():
	get_tree().change_scene_to(level)

func _quit():
	get_tree().quit()
