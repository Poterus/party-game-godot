extends Node2D

# --- CONFIGURACIÓN ---
# ¡OJO! Hemos borrado @export var player_scene de aquí. 
# Ahora debes arrastrar el player.tscn al Inspector del nodo SpawnManager.
@export var anvil_scene: PackedScene     # Arrastra tu obstaculo.tscn aquí

@onready var game_timer: Timer = $Timer
@onready var spawn_manager: Node2D = $SpawnManager
@onready var countdown_ui: CanvasLayer = $CountdownUI

@onready var victory_ui: CanvasLayer = $UIVictory # Arrastra tu nueva escena al nivel
@onready var hud_ui: CanvasLayer = $UiHud # Ajusta el nombre según lo llamaras

var game_active: bool = false
var time_survived: float = 0.0
# --- ESTADO ---
var players_alive: int = 0

func _ready() -> void:
	# 1. Limpiamos primero
	_clear_test_players()
	
	# 2. Spawneamos
	players_alive = spawn_manager.spawn_all_players(
		NetworkManager.current_play_mode, 
		NetworkManager.host_plays_on_pc, 
		NetworkManager.connected_phones.size()
	)
	hud_ui.create_icons(players_alive, NetworkManager.host_plays_on_pc)
	# --- ESTA ES LA LÍNEA QUE FALTABA ---
	game_timer.timeout.connect(_on_anvil_timer_timeout)
	
	# 3. Conectamos y arrancamos la UI
	countdown_ui.countdown_finished.connect(_on_start_game)
	countdown_ui.start_countdown()
	
func _on_start_game():
	print("¡La lluvia de yunques comienza ahora!")
	game_timer.start()
	game_active = true # <--- NUEVO
	
	for child in get_children():
		if child.name.begins_with("Player"):
			child.can_move = true

# NUEVA FUNCIÓN: Para contar los segundos si jugamos solos
func _process(delta: float) -> void:
	if game_active and NetworkManager.current_play_mode == "solo":
		time_survived += delta
	
func _clear_test_players() -> void:
	# Por si dejaste algún jugador suelto en el editor para ver la escala
	for child in get_children():
		if child.name.begins_with("Player"):
			child.queue_free()

# ==========================================
# LÓGICA DE JUEGO (YUNQUES)
# ==========================================
func _on_anvil_timer_timeout() -> void:
	var nuevo_yunque = anvil_scene.instantiate()
	var random_x = randf_range(32, 608) # Ajusta esto a 640 si el ancho de tu juego es 640!
	nuevo_yunque.global_position = Vector2(random_x, -100)
	add_child(nuevo_yunque)
	
	# --- NUEVO: AUMENTO DE DIFICULTAD ---
	# Restamos 0.05 segundos al tiempo de espera.
	var nuevo_tiempo = game_timer.wait_time - 0.1
	
	# El límite máximo de dificultad es 0.2 segundos (caos total).
	# Si aún no hemos llegado al límite, aplicamos el nuevo tiempo.
	if nuevo_tiempo > 0.2:
		game_timer.wait_time = nuevo_tiempo
	else:
		game_timer.wait_time = 0.2

# ==========================================
# SISTEMA DE ELIMINACIÓN
# ==========================================
func player_died(id: int) -> void:
	players_alive -= 1
	print("Jugador ", id, " ELIMINADO. Quedan: ", players_alive)
	
	hud_ui.update_player_death(id)
	
	if players_alive <= 1:
		_end_minigame()

func _end_minigame() -> void:
	game_timer.stop()
	game_active = false
	
	if NetworkManager.current_play_mode == "solo":
		victory_ui.show_singleplayer_score(time_survived)
	else:
		var winner_id = _get_winner_id()
		victory_ui.show_multiplayer_winner(winner_id)
   
# ==========================================
# FUNCIONES AUXILIARES
# ==========================================
func _get_winner_id() -> int:
	var winner = -1
	# Solo buscamos ganador si queda exactamente 1 vivo
	if players_alive == 1:
		for child in get_children():
			# Si el nodo es un Jugador y NO está a punto de ser borrado de la memoria
			if child.name.begins_with("Player") and not child.is_queued_for_deletion():
				winner = child.my_player_id
	return winner
	# IMPORTANTE: Ya no ponemos el await ni el cambio de escena aquí, 
	# porque ahora el jugador decidirá cuándo irse pulsando un botón.


func _on_debug_kill_button_pressed() -> void:
	# 1. Creamos una lista con todos los jugadores que siguen vivos
	var alive_players = []
	for child in get_children():
		if child.name.begins_with("Player") and not child.is_queued_for_deletion():
			alive_players.append(child)
	
	# 2. Si hay alguien a quien matar, elegimos uno al azar
	if alive_players.size() > 0:
		var target = alive_players.pick_random()
		var target_id = target.my_player_id
		
		print("DEBUG: Eliminando al jugador ", target_id)
		
		# 3. Lo borramos y avisamos al sistema de muerte
		target.queue_free()
		player_died(target_id)
