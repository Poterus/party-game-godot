extends Node2D

# --- EXPORTS (Configúralos en el Inspector) ---
@export var player_scene: PackedScene    # Tu player.tscn
@export var anvil_scene: PackedScene     # Tu obstaculo.tscn (el yunque)

@onready var spawn_points: Node2D = $SpawnPoints
@onready var game_timer: Timer = $Timer # El Timer que ya tenías

# --- VARIABLES DE ESTADO ---
var players_alive: int = 0

func _ready() -> void:
	# 1. Al empezar, generamos a los jugadores que haya en la sala
	_setup_multiplayer_game()
	
	# 2. Conectamos tu Timer para que empiecen a caer yunques
	game_timer.timeout.connect(_on_anvil_timer_timeout)

# ==========================================
# GESTIÓN DE JUGADORES (Hasta 8)
# ==========================================
func _setup_multiplayer_game() -> void:
	var markers = spawn_points.get_children()
	var spawn_index = 0
	
	# Determinamos cuántos y quiénes entran según el modo
	var players_to_spawn = []
	
	if NetworkManager.current_play_mode == "solo":
		players_to_spawn = [1]
	else:
		# Si estamos en Local/Online, llenamos la lista
		if NetworkManager.host_plays_on_pc:
			players_to_spawn.append(1)
		
		for i in range(NetworkManager.connected_phones.size()):
			var p_id = (i + 2) if NetworkManager.host_plays_on_pc else (i + 1)
			players_to_spawn.append(p_id)
	
	# Spawneamos a cada uno en su sitio
	for p_id in players_to_spawn:
		if spawn_index < markers.size():
			_spawn_single_player(p_id, markers[spawn_index].global_position)
			spawn_index += 1

func _spawn_single_player(id: int, pos: Vector2) -> void:
	var p = player_scene.instantiate()
	p.my_player_id = id
	p.name = "Player_" + str(id)
	p.position = pos
	
	# --- ESTA ES LA LÍNEA MÁGICA ---
	# 0 es HORIZONTAL, 1 es TOP_DOWN (según el enum que pusimos)
	p.mode = 0 
	
	add_child(p)
	players_alive += 1

# ==========================================
# TU LÓGICA RECICLADA (Lluvia de Yunques)
# ==========================================
func _on_anvil_timer_timeout() -> void:
	# Este es el código que ya tenías, pero usando la nueva variable
	var nuevo_yunque = anvil_scene.instantiate()
	
	# Posición aleatoria entre los bordes
	var random_x = randf_range(50, 1100)
	nuevo_yunque.position = Vector2(random_x, -50)
	
	add_child(nuevo_yunque)

# ==========================================
# SISTEMA DE ELIMINACIÓN
# ==========================================
func player_died(id: int) -> void:
	players_alive -= 1
	print("Jugador ", id, " eliminado. Quedan: ", players_alive)
	
	if players_alive <= 1:
		_end_minigame()

func _end_minigame() -> void:
	game_timer.stop()
	print("¡Fin del juego!")
	# Aquí podrías poner un cartel de victoria antes de volver al menú
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://ui/menus/mode_selection/mode_selection.tscn")
