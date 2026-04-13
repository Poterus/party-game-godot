extends Control

# ==========================================
# REFERENCIAS A LOS BOTONES
# ==========================================
@onready var btn_local: Button = $MarginContainer/VBoxContainer/ButtonLocal
@onready var btn_online: Button = $MarginContainer/VBoxContainer/ButtonOnline
@onready var btn_single: Button = $MarginContainer/VBoxContainer/ButtonSingle
@onready var btn_options: Button = $MarginContainer/VBoxContainer/ButtonOptions
@onready var btn_quit: Button = $MarginContainer/VBoxContainer/ButtonQuit

func _ready() -> void:
	# Conectamos todos los botones a sus funciones correspondientes
	btn_local.pressed.connect(_on_local_pressed)
	btn_online.pressed.connect(_on_online_pressed)
	btn_single.pressed.connect(_on_single_pressed)
	btn_options.pressed.connect(_on_options_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

# ==========================================
# LÓGICA DE NAVEGACIÓN
# ==========================================
func _on_local_pressed() -> void:
	NetworkManager.current_play_mode = "local"
	get_tree().change_scene_to_file("res://ui/menus/lobby/lobby_local.tscn")

func _on_online_pressed() -> void:
	NetworkManager.current_play_mode = "online"
	get_tree().change_scene_to_file("res://ui/menus/lobby/lobby_online.tscn")

func _on_single_pressed() -> void:
	NetworkManager.current_play_mode = "solo"
	get_tree().change_scene_to_file("res://ui/menus/mode_selection/mode_selection.tscn")

func _on_options_pressed() -> void:
	print("Abriendo menú de opciones...")
	# Aquí pondrás la ruta a tu escena de opciones cuando la crees. Ej:
	# get_tree().change_scene_to_file("res://ui/menus/options/options.tscn")

func _on_quit_pressed() -> void:
	print("Cerrando el juego...")
	# Esta es la función nativa de Godot para cerrar la aplicación de forma segura
	get_tree().quit()
