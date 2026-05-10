extends Node2D
class_name BaseMinigame # ¡Esto es magia! Convierte este script en un Nodo base

# --- REFERENCIAS OBLIGATORIAS PARA TODOS LOS NIVELES ---
@export var spawn_manager: Node2D
@export var countdown_ui: CanvasLayer
@export var victory_ui: PackedScene
@export var hud_ui: CanvasLayer

# --- ESTADO INTERNO ---
var game_active: bool = false
var time_survived: float = 0.0
var players_alive: int = 0
var initial_players_count: int = 0
var is_solo_mode: bool = false
var is_game_over: bool = false

func _ready() -> void:
	# 1. Spawneamos a los jugadores
	is_solo_mode = (NetworkManager.current_play_mode == "solo")
	
	# CAMBIO AQUÍ: En lugar de connected_phones.size(), usamos player_faces.size()
	# Esto incluye a los bots de debug y a los jugadores reales que ya tienen foto.
	var total_players = NetworkManager.player_faces.size()
	
	var spawned_players = spawn_manager.spawn_all_players(
		NetworkManager.current_play_mode, 
		NetworkManager.host_plays_on_pc, 
		total_players # <--- Ahora esto enviará el número correcto (ej: 3 si diste 3 veces al botón)
	)
	
	players_alive = spawned_players.size()
	initial_players_count = players_alive
	hud_ui.create_icons(players_alive, NetworkManager.host_plays_on_pc)
	
	# 2. Conectamos señales y configuramos a los jugadores
	for p in spawned_players:
		p.player_died.connect(_on_player_died_base)
		_setup_custom_player(p) # <--- GANCHO PARA FUTUROS MINIJUEGOS
		
	# 3. Arrancamos la UI
	countdown_ui.countdown_finished.connect(_internal_start_game)
	countdown_ui.start_countdown()

func _process(delta: float) -> void:
	if game_active and is_solo_mode:
		time_survived += delta

func _internal_start_game():
	game_active = true
	# Desbloqueamos el movimiento
	for child in spawn_manager.get_parent().get_children():
		if child.name.begins_with("Player") and not child.is_dead:
			child.can_move = true
			
	# Avisamos al minijuego específico de que puede empezar
	_minigame_start()

func _on_player_died_base(id: int) -> void:
	if is_game_over: return
	
	players_alive -= 1
	hud_ui.update_player_death(id)
	
	# Avisamos al minijuego específico por si quiere hacer algo (ej. dar puntos al asesino)
	_minigame_player_died(id)
	
	if is_solo_mode:
		if players_alive <= 0: _end_minigame_base()
	else:
		if players_alive <= 1: _end_minigame_base()

func _end_minigame_base() -> void:
	if is_game_over: return
	is_game_over = true
	game_active = false
	
	# Avisamos al minijuego de que pare sus peligros (ej. dejar de spawnear yunques)
	_minigame_end()
	
	await get_tree().create_timer(1.5).timeout
	
	if victory_ui:
		var victory_screen = victory_ui.instantiate()
		get_tree().root.add_child(victory_screen)
		if is_solo_mode:
			victory_screen.show_singleplayer_score(time_survived)
		else:
			victory_screen.show_multiplayer_winner(_get_winner_id())

func _get_winner_id() -> int:
	if players_alive == 1:
		for child in spawn_manager.get_parent().get_children():
			if child.name.begins_with("Player") and not child.is_dead:
				return child.my_player_id
	return -1


# =========================================================
# FUNCIONES "VIRTUALES" (GANCHOS)
# Estas funciones están vacías aquí, pero las sobrescribiremos 
# en cada minijuego (yunques, carreras, etc.)
# =========================================================
func _minigame_start() -> void:
	pass

func _minigame_end() -> void:
	pass

func _minigame_player_died(_id: int) -> void:
	pass

func _setup_custom_player(_player: Node2D) -> void:
	pass
