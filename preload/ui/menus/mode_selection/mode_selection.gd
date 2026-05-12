extends Control

@onready var button_board: Button = $MarginContainer/VBoxContainer/ButtonBoard
@onready var button_mini: Button = $MarginContainer/VBoxContainer/ButtonMini
@onready var button_back: Button = $MarginContainer/VBoxContainer/ButtonBack

func _ready() -> void:
	button_board.pressed.connect(_on_board_pressed)
	button_mini.pressed.connect(_on_mini_pressed)
	button_back.pressed.connect(_on_back_pressed) # NUEVO
	button_mini.grab_focus()

func _on_board_pressed() -> void:
	#get_tree().change_scene_to_file("res://ui/menus/lobby/lobby_local.tscn")
	pass
	
func _on_mini_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/menus/minigame_selection/minigame_selection.tscn")

# NUEVA FUNCIÓN PARA JUGAR SOLO
func _on_back_pressed() -> void:
	# Le preguntamos al Autoload de dónde venimos
	if NetworkManager.current_play_mode == "solo":
		# Si estamos solos, el menú anterior era el Principal
		get_tree().change_scene_to_file("res://ui/menus/main_menu/main_menu.tscn")
	else:
		# Si estamos con amigos, el menú anterior era el Lobby Local
		get_tree().change_scene_to_file("res://ui/menus/lobby/lobby_local.tscn")
