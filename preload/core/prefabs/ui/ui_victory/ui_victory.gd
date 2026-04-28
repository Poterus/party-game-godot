extends CanvasLayer

@onready var title_label = %TitleLabel
@onready var result_label = %ResultLabel

func _ready():
	hide()
	# Conectamos las señales de los botones por código para mayor seguridad
	%RetryButton.pressed.connect(_on_retry_pressed)
	%PickGameButton.pressed.connect(_on_pick_game_pressed)
	%ExitMenuButton.pressed.connect(_on_exit_menu_pressed)

# --- MÉTODOS DE VISUALIZACIÓN ---

func show_multiplayer_winner(winner_id: int):
	show()
	title_label.text = "¡FIN DE LA PARTIDA!"
	if winner_id > 0:
		result_label.text = "¡Ganó el Jugador " + str(winner_id) + "!"
		result_label.modulate = Color.from_hsv(winner_id * 0.125, 0.8, 1.0)
	else:
		result_label.text = "¡EMPATE!"
		result_label.modulate = Color.WHITE

func show_singleplayer_score(time_survived: float):
	show()
	title_label.text = "¡HAS CAÍDO!"
	var time_text = str(snapped(time_survived, 0.1))
	result_label.text = "Tiempo: " + time_text + " segundos"
	result_label.modulate = Color.YELLOW

# --- LÓGICA DE LOS BOTONES ---

func _on_retry_pressed():
	# Recarga la escena actual en la que estés (el minijuego actual)
	get_tree().reload_current_scene()
	queue_free() # Nos eliminamos a nosotros mismos para asegurar limpieza

func _on_pick_game_pressed():
	# Vuelve a la pantalla de selección de minijuegos
	get_tree().change_scene_to_file("res://ui/menus/minigame_selection/minigame_selection.tscn")

func _on_exit_menu_pressed():
	# Vuelve al menú principal o de modos
	get_tree().change_scene_to_file("res://ui/menus/mode_selection/mode_selection.tscn")
	queue_free()
