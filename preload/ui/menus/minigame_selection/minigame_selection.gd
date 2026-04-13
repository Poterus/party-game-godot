extends Control

@onready var btn_yunque: Button = $MarginContainer/VBoxContainer/GridMinigames/ButtonYunque
@onready var btn_back: Button = $MarginContainer/VBoxContainer/ButtonBack

func _ready() -> void:
	btn_yunque.pressed.connect(_on_yunque_pressed)
	btn_back.pressed.connect(_on_back_pressed)

# ==========================================
# LÓGICA INTELIGENTE DE MINIJUEGOS
# ==========================================
func _on_yunque_pressed() -> void:
	match NetworkManager.current_play_mode:
		"solo":
			get_tree().change_scene_to_file("res://minigames/yunque/yunque.tscn")
			
		"local":
			# ¡Ahora la llamada es súper corta y limpia!
			NetworkManager.send_layout_to_all("joystick")
			get_tree().change_scene_to_file("res://minigames/yunque/yunque.tscn")
			
func _on_back_pressed() -> void:
	# Como a esta pantalla siempre llegamos desde la Selección de Modo, 
	# el botón Back siempre nos lleva ahí, independientemente del modo de juego.
	get_tree().change_scene_to_file("res://ui/menus/mode_selection/mode_selection.tscn")
