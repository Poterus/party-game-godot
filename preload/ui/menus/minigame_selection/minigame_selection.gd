extends Control

@onready var btn_yunque: Button = $MarginContainer/VBoxContainer/GridMinigames/ButtonYunque
@onready var btn_sprint: Button = $MarginContainer/VBoxContainer/GridMinigames/ButtonSprint
@onready var btn_back: Button = $MarginContainer/VBoxContainer/ButtonBack

func _ready() -> void:
	btn_yunque.pressed.connect(_on_yunque_pressed)
	btn_sprint.pressed.connect(_on_sprint_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	btn_yunque.grab_focus()

# ==========================================
# LÓGICA INTELIGENTE DE MINIJUEGOS
# ==========================================
func _on_yunque_pressed() -> void:
	match NetworkManager.current_play_mode:
		"solo":
			get_tree().change_scene_to_file("res://minigames/yunque/yunque.tscn")
			
		"local":
			get_tree().change_scene_to_file("res://minigames/yunque/yunque.tscn")

func _on_sprint_pressed() -> void:
	match NetworkManager.current_play_mode:
		"solo":
			get_tree().change_scene_to_file("res://minigames/sprint/sprint.tscn")
			
		"local":
			get_tree().change_scene_to_file("res://minigames/sprint/sprint.tscn")
			
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/menus/mode_selection/mode_selection.tscn")
